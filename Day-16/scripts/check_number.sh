#!/bin/bash
# Description: Determine if a given number is positive, negative, or zero

read -p "Enter a number: " NUM

if (( NUM > 0 )); then
    echo "The number $NUM is positive."
elif (( NUM < 0 )); then
    echo "The number $NUM is negative."
else
    echo "The number is zero."
fi