#!/bin/bash
# Description Demonstrate the Difference between global and local variables

#Global variable
USER_ROLE="Admin"

demo_scope(){
    #Local variable (Only exists inside this function)
    local INTERNAL_VAR="Secret Data"

    # Modifying the Global variables
    USER_ROLE="Guest"

    echo "Inside Function: INTERNAL_VAR= $INTERNAL_VAR"
    echo "Inside Function: USER_ROLE= $USER_ROLE"
}

echo "Before function: USER_ROLE = $USER_ROLE"

demo_scope

echo "After function: USER_ROLE= $USER_ROLE"
echo "After function: INTERNAL_VAR= $INTERNAL_VAR (Notice this is blank!)"
