#!/bin/bash
set -e

export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HIVE_HOME/bin

PROJECT_ROOT="/mnt/c/bigdata/big-data-analytics-group-assignemnt"
EMP_DATA="$PROJECT_ROOT/data/EmployeeDataset.csv"
STU_DATA="$PROJECT_ROOT/data/student_performance.csv"

echo "=== Starting HDFS & YARN ==="
/opt/hadoop/sbin/start-dfs.sh
/opt/hadoop/sbin/start-yarn.sh

echo "Waiting for HDFS to exit safemode..."
hdfs dfsadmin -safemode wait || true

echo "=== Uploading Datasets to HDFS ==="
hdfs dfs -mkdir -p /data/employee
hdfs dfs -put -f "$EMP_DATA" /data/employee/EmployeeDataset.csv

hdfs dfs -mkdir -p /user/hive/student_data
hdfs dfs -put -f "$STU_DATA" /user/hive/student_data/student_performance.csv

echo "=== Starting Hive Metastore ==="
# Kill any existing metastore
pkill -f "org.apache.hadoop.hive.metastore.HiveMetaStore" || true
nohup /opt/hive/bin/hive --service metastore > /opt/hive/logs/metastore.log 2>&1 &

echo "Waiting for Metastore to open port 9083..."
for i in {1..30}; do
    if ss -tulpn | grep -q 9083; then
        echo "Metastore is up!"
        break
    fi
    sleep 2
done

echo "=== Running Employee Assignment ==="
/opt/hive/bin/beeline -u jdbc:hive2:// -n hive -f "$PROJECT_ROOT/scripts/employee_analysis.hql" > "$PROJECT_ROOT/employee_hive_output.txt" 2>&1

echo "=== Running Student Assignment ==="
/opt/hive/bin/beeline -u jdbc:hive2:// -n hive -f "$PROJECT_ROOT/scripts/student_queries.sql" > "$PROJECT_ROOT/scripts/student_hive_output.txt" 2>&1

echo "=== Running Report Generators ==="
cd "$PROJECT_ROOT/scripts"
python3 create_student_report.py

echo "=== ALL ASSIGNMENTS COMPLETED SUCCESSFULLY ==="
