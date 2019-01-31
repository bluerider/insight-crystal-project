## let's try creating a spark context for the S3 files
function classifyImagesMarco {
    ## get the needed config
    source config/bash/env.sh
    ## get the needed hostnames
    spark_hosts=($(cat ${PEGASUS_HOME}/tmp/crystal-project-spark-cluster/public_dns))
    postgresql_hosts=($(cat ${PEGASUS_HOME}/tmp/crystal-project-database-cluster/public_dns))
    ## getting the marco saved model
    echo "Getting marco trained model..."
    wget https://storage.googleapis.com/marco-168219-model/savedmodel.zip
    unzip savedmodel.zip
    ## copy the pyspark python script
    echo "Copying python script to spark master..."
    scp src/python/classifyImagesMarco.py ubuntu@${spark_hosts[0]}:
    echo "Copying marco saved model to spark master..."
    scp savedmodel/saved_model.pb ubuntu@${spark_hosts[0]}:

    ## launch the command
    echo "Running spark classification job..."
    ssh ubuntu@${spark_hosts[0]} "
        export PYSPARK_PYTHON=python3
        export LD_LIBRARY_PATH+=:/usr/local/hadoop/lib/native
        export SPARK_HOME=/usr/local/spark
        export HADOOP_HOME=/usr/local/hadoop
        spark-submit --packages org.apache.hadoop:hadoop-aws:2.7.1,databricks:spark-deep-learning:0.3.0-spark2.2-s_2.11,org.postgresql:postgresql:42.1.4 --master spark://${spark_hosts[0]}:7077 --executor-memory 10G --driver-memory 40G --files saved_model.pb --py-files classifyImagesMarco.py classifyImagesMarco.py $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY $AWS_DEFAULT_REGION ${postgresql_hosts[0]} $POSTGRES_USER $POSTGRES_PASSWORD
        "
}