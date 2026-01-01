#!/bin/bash

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "Python not found. Please install Python 3.12.10 manually."
    exit 1
fi

# Ensure venv exists
if [ ! -d "myenv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv myenv
fi

# Activate venv
source myenv/bin/activate

# Install requirements
pip install --upgrade pip
pip install -r requirements.txt

echo "Setup complete."
