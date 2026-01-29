#!/bin/bash

"""
GitHub Actions Fixer - Run Script

This script runs the GitHub Actions fixer Python script.
"""

set -e

# Print banner
echo "===================================="
echo "📋 GitHub Actions Fixer"
echo "===================================="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed"
    exit 1
fi

echo "✅ Python 3 is installed"

# Check if required packages are installed
echo "📦 Checking required packages..."
if ! python3 -c "import yaml" &> /dev/null; then
    echo "📦 Installing PyYAML..."
    pip3 install pyyaml --quiet
    echo "✅ PyYAML installed"
else
    echo "✅ PyYAML is already installed"
fi

# Run the fixer script
echo "\n🚀 Running GitHub Actions Fixer..."
python3 "$(dirname "$0")/fixer.py" "$@"

# Check exit code
if [ $? -eq 0 ]; then
    echo "\n🎉 GitHub Actions Fixer completed successfully!"
    exit 0
else
    echo "\n❌ GitHub Actions Fixer encountered errors!"
    exit 1
fi
