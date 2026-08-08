#!/bin/bash
# Description: Countdown timer using a while loop

read -p "Enter the Starting Number: " COUNT

while [ "$COUNT" -ge 0 ]; do
    echo "$COUNT"
    COUNT=$((COUNT - 1))
    sleep 0.5
done

echo "Done!"