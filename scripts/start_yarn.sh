#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

echo "=== Starting YARN ResourceManager ==="
/opt/hadoop/sbin/yarn-daemon.sh start resourcemanager
echo "Exit code: $?"

sleep 5

echo ""
echo "=== Verifying ResourceManager started ==="
pgrep -la ResourceManager 2>&1 || echo "ResourceManager still not found"

echo ""
echo "=== Port 8032 (RPC) ==="
ss -tlnp | grep 8032 || echo "Port 8032 not listening yet"

echo ""
echo "=== Port 8088 (Web UI) ==="
ss -tlnp | grep 8088 || echo "Port 8088 not listening yet"

echo ""
echo "=== All running Hadoop JVM processes ==="
jps

echo ""
echo "=== YARN node list (after start) ==="
/opt/hadoop/bin/yarn node -list 2>&1 | head -20
