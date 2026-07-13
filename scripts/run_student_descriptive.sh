#!/bin/bash
# Wait for the ALREADY-RUNNING HiveServer2 (PID 15267) to bind port 10000
# then run the descriptive HQL

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HQL_FILE="$SCRIPT_DIR/student_descriptive.hql"
OUT_DIR="$SCRIPT_DIR/output"
OUT_FILE="$OUT_DIR/student_descriptive_output.txt"
mkdir -p "$OUT_DIR"

echo "=== Re-upload dataset to HDFS ==="
/opt/hadoop/bin/hdfs dfs -put -f \
  /mnt/c/bigdata/big-data-analytics-group-assignemnt/data/student_performance.csv \
  /data/BigData_Student_Performance_Dataset_1000.csv 2>&1
echo "Done."

echo ""
echo "=== HiveServer2 process check ==="
jps | grep RunJar || echo "No RunJar found — HS2 may have died"

echo ""
echo "Waiting up to 5 minutes for port 10000 to open..."
READY=0
for i in $(seq 1 150); do
    if ss -tln 2>/dev/null | grep -q ':10000'; then
        READY=1
        echo ""
        echo "HiveServer2 READY after $((i*2))s!"
        break
    fi
    printf "."
    sleep 2
done

if [ $READY -eq 0 ]; then
    echo ""
    echo "HS2 still not on port 10000 after 5 min. Last 40 lines of log:"
    tail -40 /opt/hive/logs/hiveserver2.log 2>/dev/null
    echo ""
    echo "=== Starting fresh HS2 and waiting 5 more minutes ==="
    pkill -9 -f RunJar 2>/dev/null || true
    sleep 3
    nohup hiveserver2 > /opt/hive/logs/hiveserver2.log 2>&1 &
    echo "New HS2 PID: $!"
    for i in $(seq 1 150); do
        if ss -tln 2>/dev/null | grep -q ':10000'; then
            READY=1
            echo "HS2 READY on 2nd attempt after $((i*2))s"
            break
        fi
        printf "."
        sleep 2
    done
fi

if [ $READY -eq 0 ]; then
    echo ""
    echo "FATAL: HiveServer2 cannot start. Full log:"
    cat /opt/hive/logs/hiveserver2.log
    exit 1
fi

echo ""
echo "=== Extra settle: 8s ==="
sleep 8

echo ""
echo "=== Test Beeline connection ==="
beeline -u "jdbc:hive2://localhost:10000" -n ambsh -p "" \
  --silent=true -e "SELECT 'HIVE_OK' AS status;" 2>&1 | tail -5

echo ""
echo "=== Running Full 14-Section Descriptive HQL ==="
beeline -u "jdbc:hive2://localhost:10000" -n ambsh -p "" \
  --silent=false \
  --hiveconf mapreduce.task.io.sort.mb=32 \
  --hiveconf hive.exec.mode.local.auto=true \
  -f "$HQL_FILE" \
  2>&1 | tee "$OUT_FILE"

echo ""
echo "=== DONE ==="
echo "Output: $OUT_FILE  |  Lines: $(wc -l < "$OUT_FILE")"
