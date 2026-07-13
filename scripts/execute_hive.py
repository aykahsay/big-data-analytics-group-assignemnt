import os
import subprocess

sh_script = """#!/bin/bash
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HIVE_HOME/bin

/opt/hive/bin/hive -f /mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/assignment_queries.sql > /mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/hive_output.txt 2>&1
"""

with open('run_hive_clean.sh', 'w', newline='\n') as f:
    f.write(sh_script)

result = subprocess.run(['wsl', 'bash', 'run_hive_clean.sh'], capture_output=True, text=True)
print("STDOUT:", result.stdout)
print("STDERR:", result.stderr)
