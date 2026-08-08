#!/bin/bash
#Description: Loop Through a list of fruits

FRUITS=("Apple" "Banana" "Cherry" "Mango" "orange")

for FRUIT in "${FRUITS[@]}"; do
    echo "Fruit: $FRUIT"

done