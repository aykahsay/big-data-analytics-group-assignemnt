#!/bin/bash
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HIVE_HOME/bin

PROJECT_ROOT="/mnt/c/bigdata/big-data-analytics-group-assignemnt"

echo "=== Running Employee Assignment ==="
/opt/hive/bin/beeline -u jdbc:hive2:// -n hive -f "$PROJECT_ROOT/scripts/employee_analysis.hql" > "$PROJECT_ROOT/employee_hive_output.txt" 2>&1

echo "=== Running Student Assignment ==="
/opt/hive/bin/beeline -u jdbc:hive2:// -n hive -f "$PROJECT_ROOT/scripts/student_queries.sql" > "$PROJECT_ROOT/scripts/student_hive_output.txt" 2>&1

echo "=== Generating PNGs and LaTeX ==="
cd "$PROJECT_ROOT/scripts"
python3 create_student_report.py
python3 txt_to_png.py ../images
echo "DONE"
