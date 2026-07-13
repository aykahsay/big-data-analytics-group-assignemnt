#!/usr/bin/env bash

# Setup environment variables
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

echo "Uploading student_scores.csv to HDFS (/data/student_scores.csv)..."
hdfs dfs -mkdir -p /data
hdfs dfs -put -f /home/ambsh/big-data-analytics-group-assignemnt/data/student_scores.csv /data/student_scores.csv

echo "Executing Hive preprocessing script (preprocess.hql) via Beeline..."
beeline -u jdbc:hive2://localhost:10000 -n ambsh -p "" -f /home/ambsh/big-data-analytics-group-assignemnt/scripts/preprocess.hql
