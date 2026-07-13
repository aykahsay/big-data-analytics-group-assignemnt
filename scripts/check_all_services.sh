#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

echo "============================================"
echo "  SERVICE CONNECTIVITY CHECK"
echo "============================================"
echo ""

# ---- HDFS ----
echo "=== [1] HDFS STATUS ==="
if hdfs dfsadmin -report 2>&1 | head -40; then
    echo "[HDFS] Report command executed."
else
    echo "[HDFS] dfsadmin -report failed."
fi

echo ""
echo "--- HDFS: NameNode status ---"
hdfs dfsadmin -safemode get 2>&1

echo ""
echo "--- HDFS: List root directory ---"
hdfs dfs -ls / 2>&1

echo ""
echo "============================================"
echo "=== [2] YARN STATUS ==="
yarn node -list 2>&1 | head -30

echo ""
echo "--- YARN: ResourceManager report ---"
yarn rmadmin -getServiceState rm 2>&1

echo ""
echo "============================================"
echo "=== [3] POSTGRESQL CONNECTION ==="
echo "--- Testing psql connection ---"
if command -v psql &>/dev/null; then
    psql -U hive -d metastore -c "SELECT version();" 2>&1
    echo "--- PostgreSQL: Checking metastore tables ---"
    psql -U hive -d metastore -c "\dt" 2>&1 | head -20
else
    echo "[PostgreSQL] psql client not found in PATH."
    # Try common locations
    for loc in /usr/bin/psql /usr/local/bin/psql /opt/postgresql/bin/psql; do
        if [ -f "$loc" ]; then
            echo "Found psql at $loc"
            $loc -U hive -d metastore -c "SELECT version();" 2>&1
        fi
    done
fi

echo ""
echo "--- Hive metastore schematool check ---"
if command -v schematool &>/dev/null; then
    schematool -dbType postgres -info 2>&1
else
    /opt/hive/bin/schematool -dbType postgres -info 2>&1
fi

echo ""
echo "============================================"
echo "  ALL CHECKS DONE"
echo "============================================"
