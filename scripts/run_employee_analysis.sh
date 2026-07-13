#!/usr/bin/env bash
# =============================================================================
# Script: run_employee_analysis.sh
# Purpose: One-shot runner: upload dataset to HDFS then execute Hive analysis
# Usage:   bash scripts/run_employee_analysis.sh  (from project root)
# =============================================================================

set -e   # exit on first error

export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATASET_LOCAL="$PROJECT_ROOT/data/EmployeeDataset.csv"
DATASET_HDFS="/data/employee/EmployeeDataset.csv"
HQL_SCRIPT="$SCRIPT_DIR/employee_analysis.hql"
LOG_FILE="$PROJECT_ROOT/employee_analysis_$(date +%Y%m%d_%H%M%S).log"

echo "============================================================"
echo "  Big Data Analytics – Employee Dataset Analysis Runner"
echo "============================================================"
echo "  Project root : $PROJECT_ROOT"
echo "  Dataset      : $DATASET_LOCAL"
echo "  HDFS path    : $DATASET_HDFS"
echo "  HQL script   : $HQL_SCRIPT"
echo "  Log file     : $LOG_FILE"
echo "============================================================"

# ---- Step 1: Start HDFS if needed ----
echo ""
echo "[STEP 1] Checking HDFS..."
hdfs dfsadmin -report > /dev/null 2>&1 || {
    echo "  Starting HDFS and YARN..."
    start-dfs.sh && start-yarn.sh
    sleep 10
}
echo "  HDFS OK."

# ---- Step 2: Upload dataset ----
echo ""
echo "[STEP 2] Uploading EmployeeDataset.csv to HDFS..."
hdfs dfs -mkdir -p /data/employee
hdfs dfs -put -f "$DATASET_LOCAL" "$DATASET_HDFS"
echo "  Uploaded → $DATASET_HDFS"
hdfs dfs -ls "$DATASET_HDFS"

# ---- Step 3: Run Hive script ----
echo ""
echo "[STEP 3] Running Hive analysis script..."
echo "  Output will be saved to: $LOG_FILE"
echo ""

hive -f "$HQL_SCRIPT" 2>&1 | tee "$LOG_FILE"

echo ""
echo "============================================================"
echo "  Analysis complete. Results saved to:"
echo "  $LOG_FILE"
echo "============================================================"
