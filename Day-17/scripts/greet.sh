#!/bin/bash
# Description: Greet user via command line positional argument

if [ -z "$1" ]; then
    echo "Usage : ./greet.sh <name>"
    exit 1
fi

echo "Hello, $1!"