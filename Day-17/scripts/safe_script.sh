#!/bin/bash
# Description: Safe execution script with set -e and conditional operators

set -e

DIR="/tmp/devops-test"

# Create directory safely
mkdir -p "$DIR" || echo "Directory already exists or failed to create"

# Navigate to target directory
cd "$DIR" || { echo "Failed to change directory"; exit 1; }

# Create test file
touch devops_file.txt || echo "Failed to create file"

echo "Directory created and navigate successfully!"
echo "File created at: $DIR/devops_file.txt"