#!/bin/bash
expot HADOOP_HOME=/opt/hadoop
expot HIVE_HOME=/opt/hive
expot PATH=$PATH:$HADOOP_HOME/bin:$HIVE_HOME/bin

nohup /opt/hive/bin/hivesever2 > /opt/hive/logs/hiveserver2.log 2>&1 &
