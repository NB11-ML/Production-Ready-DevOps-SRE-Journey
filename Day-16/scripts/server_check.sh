#!/bin/bash
# Description: Interactive service health status checker

read -p "Enter service name: " SERVICE
read -p "Please verify you want to check status of $SERVICE: " RESPONSE

if [[ "$RESPONSE" == [yY] ]]; then
    echo "Checking status for service: $SERVICE..."
    if systemctl is-active --quiet "$SERVICE"; then
        echo "Service '$SERVICE' is ACTIVE."
    else
        echo "Service '$SERVICE' is NOT Active."
    fi
elif [[ "$RESPONSE" == [nN] ]]; then
    echo "Skipped."
else
    echo "Invalid response. Please Enter 'y' or 'n'."
fi 
