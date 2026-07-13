#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

echo "=== YARN QUICK STATUS CHECK ==="
echo ""

# Check if ResourceManager process is running
echo "--- YARN ResourceManager process ---"
pgrep -la ResourceManager 2>&1 || echo "ResourceManager process NOT found"

echo ""
echo "--- YARN NodeManager process ---"
pgrep -la NodeManager 2>&1 || echo "NodeManager process NOT found"

echo ""
echo "--- Port 8032 (RM RPC) listening? ---"
ss -tlnp 2>/dev/null | grep 8032 || netstat -tlnp 2>/dev/null | grep 8032 || echo "Nothing listening on port 8032"

echo ""
echo "--- Port 8088 (RM Web UI) listening? ---"
ss -tlnp 2>/dev/null | grep 8088 || netstat -tlnp 2>/dev/null | grep 8088 || echo "Nothing listening on port 8088"

echo ""
echo "--- HADOOP running processes (jps) ---"
jps 2>&1

echo ""
echo "=== DONE ==="
