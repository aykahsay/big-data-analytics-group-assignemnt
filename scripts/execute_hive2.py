import os
import subprocess
import time

sh_script = """#!/bin/bash
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HIVE_HOME/bin

# Check if hiveserver2 is listening
if ! ss -tulpn | grep -q 10000; then
    echo "Starting HiveServer2..."
    nohup /opt/hive/bin/hiveserver2 > /opt/hive/logs/hiveserver2.log 2>&1 &
    
    echo "Waiting for HiveServer2 on port 10000..."
    for i in {1..30}; do
        if ss -tulpn | grep -q 10000; then
            echo "HiveServer2 is up!"
            break
        fi
        sleep 5
    done
fi

echo "Executing Queries..."
/opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -n $(whoami) -f /mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/assignment_queries.sql > /mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/hive_output.txt 2>&1
echo "Done."
"""

with open('run_hive_clean.sh', 'w', newline='\n') as f:
    f.write(sh_script)

result = subprocess.run(['wsl', 'bash', 'run_hive_clean.sh'], capture_output=True, text=True)
print("STDOUT:", result.stdout)
print("STDERR:", result.stderr)
