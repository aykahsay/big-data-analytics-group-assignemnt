#!/usr/bin/env bash

# Setup environment variables
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

# 1. Stop existing HiveServer2
echo "Stopping existing HiveServer2..."
HIVESERVER2_PID=$(jps | grep RunJar | awk '{print $1}')
if [ ! -z "$HIVESERVER2_PID" ]; then
  echo "Found RunJar (HiveServer2/Metastore) process ID: $HIVESERVER2_PID. Killing it..."
  kill -9 $HIVESERVER2_PID
  sleep 3
else
  # Fallback to ps check
  HIVESERVER2_PID=$(ps aux | grep -v grep | grep -i hiveserver2 | awk '{print $2}')
  if [ ! -z "$HIVESERVER2_PID" ]; then
    echo "Found HiveServer2 process via ps: $HIVESERVER2_PID. Killing it..."
    kill -9 $HIVESERVER2_PID
    sleep 3
  else
    echo "No running HiveServer2 process found."
  fi
fi

# 2. Start HiveServer2 in the background
echo "Starting HiveServer2 in the background..."
mkdir -p /opt/hive/logs
nohup hiveserver2 > /opt/hive/logs/hiveserver2.log 2>&1 &

echo "Waiting for HiveServer2 to boot on port 10000 (takes about 15-20 seconds)..."
for i in {1..30}; do
  ss -tln | grep -q :10000
  if [ $? -eq 0 ]; then
    echo "HiveServer2 is active on port 10000!"
    break
  fi
  echo "  Waiting... ($i/30)"
  sleep 2
done

echo "Attempting test connection..."
beeline -u jdbc:hive2://localhost:10000 -n ambsh -p "" -e "SHOW DATABASES;"
