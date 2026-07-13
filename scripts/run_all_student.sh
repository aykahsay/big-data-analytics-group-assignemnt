#!/bin/bash
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HIVE_HOME/bin

echo "Starting Hadoop..."
/opt/hadoop/sbin/start-dfs.sh
/opt/hadoop/sbin/start-yarn.sh

echo "Waiting for HDFS to exit safemode..."
sleep 15
/opt/hadoop/bin/hdfs dfsadmin -safemode wait

echo "Uploading data to HDFS..."
/opt/hadoop/bin/hdfs dfs -mkdir -p /user/hive/student_data
/opt/hadoop/bin/hdfs dfs -put -f /mnt/c/bigdata/big-data-analytics-group-assignemnt/data/student_performance.csv /user/hive/student_data/

# Start Metastore
echo "Starting Metastore in background..."
nohup /opt/hive/bin/hive --service metastore > /opt/hive/logs/metastore.log 2>&1 &

echo "Waiting for Metastore to open port 9083..."
for i in {1..30}; do
    if ss -tulpn | grep -q 9083; then
        echo "Metastore is up!"
        break
    fi
    sleep 2
done

echo "Running Hive Queries..."
/opt/hive/bin/beeline -u jdbc:hive2:// -n $(whoami) -f /mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/student_queries.sql > /mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/student_hive_output.txt 2>&1

echo "Done"
