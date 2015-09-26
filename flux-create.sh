#!/bin/bash

echo ...Creating Kafka Topics...
kafka-topics --zookeeper localhost:2181 --create --topic ratings --partitions 1 --replication-factor 1
kafka-topics --zookeeper localhost:2181 --create --topic likes --partitions 1 --replication-factor 1

echo Creating ElasticSearch Indexes
curl -XPUT 'http://localhost:9200/pipeline/' -d '{
    "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0
    }
}'

echo ...Creating Cassandra Keyspaces Column Families and Tables...
#cqlsh -e "DROP KEYSPACE IF EXISTS pipeline;"
cqlsh -e "CREATE KEYSPACE pipeline WITH REPLICATION = { 'class': 'SimpleStrategy',  'replication_factor':1};"
#cqlsh -e "USE pipeline; DROP TABLE IF EXISTS ratings;"
cqlsh -e "USE pipeline; CREATE TABLE ratings (fromUserId int, toUserId int, rating int, batchTime bigint, PRIMARY KEY(fromUserId, toUserId));"
#cqlsh -e "USE pipeline; DROP TABLE IF EXISTS likes;"
cqlsh -e "USE pipeline; CREATE TABLE likes (fromUserId int, toUserId int, batchTime bigint, PRIMARY KEY(fromUserId, toUserId));"
#cqlsh -e "USE pipeline; DROP TABLE IF EXISTS ratings_partitioned;"
cqlsh -e "USE pipeline; CREATE TABLE ratings_partitioned (fromUserId int, toUserId int, rating int, PRIMARY KEY(toUserId, rating));"
#cqlsh -e "USE pipeline; DROP TABLE IF EXISTS genders_partitioned;"
cqlsh -e "USE pipeline; CREATE TABLE genders_partitioned (id int, gender text, PRIMARY KEY(id, gender));"

echo ...Creating and Formatting Docker-local HDFS...
hdfs namenode -format

echo ...Creating Reference Data in Hive...
#spark-sql --jars $MYSQL_CONNECTOR_JAR -e 'DROP TABLE IF EXISTS genders'
spark-sql --jars $MYSQL_CONNECTOR_JAR -e 'CREATE TABLE genders(id INT, gender STRING) USING org.apache.spark.sql.json OPTIONS (path "datasets/dating/genders.json.bz2")'
#spark-sql --jars $MYSQL_CONNECTOR_JAR -e 'DROP TABLE IF EXISTS ratings'
spark-sql --jars $MYSQL_CONNECTOR_JAR -e 'CREATE TABLE ratings(fromuserid INT, touserid INT, rating INT) USING org.apache.spark.sql.json OPTIONS (path "datasets/dating/ratings.json.bz2")
