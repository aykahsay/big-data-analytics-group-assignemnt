#!/usr/bin/env bash
# =============================================================================
# Script: upload_employee_to_hdfs.sh
# Purpose: Upload EmployeeDataset.csv to HDFS so Hive can load it
# Usage:   bash upload_employee_to_hdfs.sh
# =============================================================================

export HADOOP_HOME=/opt/hadoop
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

echo "=============================================="
echo " Hadoop Employee Dataset - HDFS Upload Script"
echo "=============================================="

# ---- Verify HDFS is running ----
echo "[1/4] Checking HDFS status..."
hdfs dfsadmin -report > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "  HDFS is not responding. Attempting to start services..."
  start-dfs.sh
  start-yarn.sh
  sleep 10
fi
echo "  HDFS is running."

# ---- Create target directory ----
echo "[2/4] Creating HDFS directory /data/employee..."
hdfs dfs -mkdir -p /data/employee
echo "  Directory created (or already exists)."

# ---- Upload dataset ----
DATASET_PATH="/home/ambsh/big-data-analytics-group-assignemnt/data/EmployeeDataset.csv"
echo "[3/4] Uploading EmployeeDataset.csv from: $DATASET_PATH"
hdfs dfs -put -f "$DATASET_PATH" /data/employee/EmployeeDataset.csv
if [ $? -eq 0 ]; then
  echo "  Upload successful."
else
  echo "  ERROR: Upload failed. Check that the file path is correct."
  exit 1
fi

# ---- Verify upload ----
echo "[4/4] Verifying upload..."
hdfs dfs -ls /data/employee/EmployeeDataset.csv
hdfs dfs -du -h /data/employee/EmployeeDataset.csv

echo ""
echo "Done. You can now run:  hive -f scripts/employee_analysis.hql"
