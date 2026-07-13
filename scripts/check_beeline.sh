#!/bin/bash
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HIVE_HOME/bin

/opt/hive/bin/beeline -u jdbc:hive2:// -n hive -e "SHOW DATABASES;"
