#!/bin/bash
# Description: Demonstrating strict mode behaviors. 
# Note: Uncomment one test at a time to see how the script fails.

set -euo pipefail

echo "Strict mode is active."

# --- Test 1: Undefined Variable ---
echo "Trying to use undefined variable: $UNSET_VAR"

# --- Test 2: Failing Command ---
# ls /directory/that/does/not/exist
# echo "This line will never run if the command above fails."

# --- Test 3: Piped Command Failure ---
# ls /fake/dir | grep "txt"
# echo "This line will never run if the pipe fails."

echo "If you see this, no strict mode rules were broken!"