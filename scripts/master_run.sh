#!/bin/bash
# ============================================================
# master_run.sh - Full pipeline: start HDFS, upload, run Hive
# Run this from inside WSL: bash /mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/master_run.sh
# ============================================================

export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$PATH

PROJECT="/mnt/c/bigdata/big-data-analytics-group-assignemnt"
IMAGES="$PROJECT/images"
DATA="$PROJECT/data/EmployeeDataset.csv"
HQL="$PROJECT/scripts/employee_analysis.hql"
LOG="$PROJECT/employee_analysis_output.log"

mkdir -p "$IMAGES"

echo "============================================================"
echo "  STEP 1: Starting HDFS and YARN"
echo "============================================================"
start-dfs.sh
sleep 8
start-yarn.sh
sleep 5

echo ""
echo "============================================================"
echo "  STEP 2: Upload EmployeeDataset.csv to HDFS"
echo "============================================================"
hdfs dfs -mkdir -p /data/employee
hdfs dfs -put -f "$DATA" /data/employee/EmployeeDataset.csv
echo "--- Verify upload ---"
hdfs dfs -ls /data/employee/

echo ""
echo "============================================================"
echo "  STEP 3: Run Hive Analysis"
echo "============================================================"
hive -f "$HQL" 2>&1 | tee "$LOG"

echo ""
echo "============================================================"
echo "  Done. Full output saved to: $LOG"
echo "============================================================"
