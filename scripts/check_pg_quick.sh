#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

echo "=== POSTGRESQL / HIVE METASTORE CHECK ==="
echo ""
echo "--- 1. Is PostgreSQL service running? ---"
pg_isready 2>&1 || echo "pg_isready not found or failed"

echo ""
echo "--- 2. psql connection test (hive user) ---"
if command -v psql &>/dev/null; then
    PGPASSWORD=hive psql -h localhost -U hive -d metastore -c "SELECT version();" 2>&1
    echo ""
    echo "--- 3. Metastore tables count ---"
    PGPASSWORD=hive psql -h localhost -U hive -d metastore -c "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema='public';" 2>&1
else
    echo "psql binary not found. Searching..."
    find /usr -name "psql" 2>/dev/null
    find /opt -name "psql" 2>/dev/null
fi

echo ""
echo "--- 4. Hive schematool info (uses postgres) ---"
/opt/hive/bin/schematool -dbType postgres -info 2>&1

echo ""
echo "=== DONE ==="
