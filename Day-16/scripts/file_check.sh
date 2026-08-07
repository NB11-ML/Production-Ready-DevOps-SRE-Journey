#!/bin/bash
# Description: verify whether a file exists in the flesystem

read -p "Enter the filename to check: " FILENAME

if [ -f "$FILENAME" ]; then
    echo "File $FILENAME exists."
else
    echo "File $FILENAME doesn't exists."
fi