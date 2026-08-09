#!/bin/bash
# Description: Demonstrate basic Bash functions and argument passing

greet(){
    echo "Hello, $1!"
}

add(){
    local SUM=$(($1 + $2))
    echo "The Sum of $1 and $2 is : $SUM"
}

# Main Execution

echo "+++++++++ calling Basic Function +++++++++"
greet "NB11ML"
greet "DevOps Engineer"

add 15 25
add 100 45