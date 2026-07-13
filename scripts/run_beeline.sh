#!/bin/bash
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HIVE_HOME/bin

cd /opt/hive/conf
/opt/hive/bin/beeline -u jdbc:hive2:// -n $(whoami) -f /mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/assignment_queries.sql > /mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/hive_output_embedded.txt 2>&1
