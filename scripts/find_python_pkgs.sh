#!/bin/bash
echo "=== Searching for existing Python venvs with packages ==="
find /mnt/c/bigdata /opt /home -name "site-packages" -type d 2>/dev/null | head -10

echo ""
echo "=== Checking pip cache ==="
pip3 cache list 2>/dev/null | grep -E "pandas|numpy|scikit|matplotlib|seaborn" | head -10

echo ""
echo "=== What pip3 knows about installed packages ==="
pip3 list 2>/dev/null | grep -E "pandas|numpy|scikit|matplotlib|seaborn|openpyxl"

echo ""
echo "=== Check existing venv ==="
ls /mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/.venv_predict/lib/python3.12/site-packages/ 2>/dev/null | grep -E "pandas|numpy|sklearn|matplotlib|seaborn" | head -20
