#!/bin/bash
echo "=== Checking BigDataProject venv ==="
/home/ambsh/BigDataProject/.venv/bin/python3 -c "import pandas, numpy, sklearn, matplotlib, seaborn; print('BigDataProject/.venv: ALL OK')" 2>&1

echo ""
echo "=== Checking home venv ==="
/home/ambsh/venv/bin/python3 -c "import pandas, numpy, sklearn, matplotlib, seaborn; print('home/venv: ALL OK')" 2>&1

echo ""
echo "=== Checking BigDataProject/venv ==="
/home/ambsh/BigDataProject/venv/bin/python3 -c "import pandas, numpy, sklearn, matplotlib, seaborn; print('BigDataProject/venv: ALL OK')" 2>&1

echo ""
echo "=== Checking dashboard venv ==="
/home/ambsh/BigDataProject/dashboard/venv/bin/python3 -c "import pandas, numpy, sklearn, matplotlib, seaborn; print('dashboard/venv: ALL OK')" 2>&1

echo ""
echo "=== Checking myproject venv ==="
/home/ambsh/myproject/venv/bin/python3 -c "import pandas, numpy, sklearn, matplotlib, seaborn; print('myproject/venv: ALL OK')" 2>&1
