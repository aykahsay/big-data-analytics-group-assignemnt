#!/bin/bash
# Fix broken venv: remove corrupt packages and force-reinstall
VENV=/mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/.venv_predict
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$SCRIPT_DIR/output"
mkdir -p "$OUT_DIR"

echo "=== Step 1: Remove corrupt packages from venv ==="
source $VENV/bin/activate

echo "Removing potentially corrupt pandas..."
pip uninstall -y pandas 2>/dev/null || true

echo "Current installed packages:"
pip list 2>/dev/null | grep -E "numpy|pandas|scikit|matplotlib|seaborn|scipy"

echo ""
echo "=== Step 2: Install packages one at a time with long timeout ==="

install_with_retry() {
    local pkg=$1
    echo ""
    echo "--- Installing: $pkg ---"
    for attempt in 1 2 3 4 5; do
        if pip install --timeout 300 --retries 10 "$pkg" 2>&1; then
            echo "  ✓ $pkg installed (attempt $attempt)"
            return 0
        fi
        echo "  Attempt $attempt failed, waiting 10s..."
        sleep 10
    done
    echo "  ✗ $pkg failed after 5 attempts"
    return 1
}

# Install in dependency order
install_with_retry "numpy"
install_with_retry "pandas"
install_with_retry "scipy"
install_with_retry "scikit-learn"
install_with_retry "matplotlib"
install_with_retry "seaborn"
install_with_retry "openpyxl"

echo ""
echo "=== Step 3: Verification ==="
python3 -c "
import numpy as np
import pandas as pd
import sklearn
import matplotlib
import seaborn
print('numpy      :', np.__version__)
print('pandas     :', pd.__version__)
print('scikit-learn:', sklearn.__version__)
print('matplotlib :', matplotlib.__version__)
print('seaborn    :', seaborn.__version__)
print()
print('ALL PACKAGES OK!')
" 2>&1

VERIFY_EXIT=$?
deactivate

if [ $VERIFY_EXIT -eq 0 ]; then
    echo ""
    echo "=== Step 4: Running Predictive Analysis ==="
    source $VENV/bin/activate
    python3 "$SCRIPT_DIR/student_predictive.py" 2>&1 | tee "$OUT_DIR/student_predictive_output.txt"
    deactivate
    echo ""
    echo "=== Predictive Analysis DONE ==="
    echo "Plots:"
    ls "$OUT_DIR"/*.png 2>/dev/null | sed 's/.*\//  → /'
else
    echo ""
    echo "Package verification FAILED — predictive analysis skipped."
fi
