#!/usr/bin/env bash

# Setup environment variables
export HADOOP_HOME=/opt/hadoop
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

echo "Checking HDFS status..."
hdfs dfsadmin -report > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "HDFS is not responding. Attempting to start HDFS..."
  start-dfs.sh
  start-yarn.sh
fi

echo "Creating HDFS directory /data..."
hdfs dfs -mkdir -p /data

echo "Uploading student_scores.csv to HDFS..."
hdfs dfs -put -f /home/ambsh/big-data-analytics-group-assignemnt/data/student_scores.csv /data/student_scores.csv

echo "Verifying upload..."
hdfs dfs -ls /data/student_scores.csv
