#!/bin/bash
# Install packages with retry and extended timeout into the existing venv
VENV=/mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/.venv_predict
source $VENV/bin/activate

echo "=== Installing packages with retry logic ==="

install_pkg() {
    local pkg=$1
    echo "Installing $pkg..."
    for attempt in 1 2 3; do
        pip install --quiet --timeout 120 --retries 5 "$pkg" && echo "  ✓ $pkg installed" && return 0
        echo "  Attempt $attempt failed, retrying..."
        sleep 5
    done
    echo "  ✗ $pkg failed after 3 attempts"
    return 1
}

install_pkg "numpy"
install_pkg "pandas"
install_pkg "scikit-learn"
install_pkg "matplotlib"
install_pkg "seaborn"
install_pkg "openpyxl"

echo ""
echo "=== Verification ==="
python3 -c "
import numpy as np
import pandas as pd
import sklearn
import matplotlib
import seaborn
print('numpy:', np.__version__)
print('pandas:', pd.__version__)
print('scikit-learn:', sklearn.__version__)
print('matplotlib:', matplotlib.__version__)
print('seaborn:', seaborn.__version__)
print('All packages OK!')
" 2>&1

deactivate
