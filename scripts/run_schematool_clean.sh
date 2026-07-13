#!/bin/bash
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HIVE_HOME/bin

rm -rf metastore_db db.lck dbex.lck derby.log
/opt/hive/bin/schematool -dbType derby -initSchema
