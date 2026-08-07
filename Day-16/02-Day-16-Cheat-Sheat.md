## 🚀 Day 16: Bash Automation Cheat Sheet

## 1. Syntax & Operator Reference Tables## File & String Test Expressions [[ ]]
Use these conditional flags inside double square brackets to check system states.

| Operator | Check Condition | Example Usage |
|---|---|---|
| -f FILE | True if file exists and is a regular file | [[ -f "server.log" ]] |
| -d DIR | True if directory exists | [[ -d "/var/log" ]] |
| -z STR | True if text string is empty | [[ -z "$TOKEN" ]] |
| -n STR | True if text string is NOT empty | [[ -n "$USER" ]] |
| == | True if text strings match exactly | [[ "$ENV" == "prod" ]] |
| != | True if text strings do not match | [[ "$ROLE" != "root" ]] |

## Math Operators (( )) vs. [[ ]]
Choose the right bracket construct depending on your preferred operator style.

| Mathematical Test | Symbol Syntax (( )) | Flag Syntax [[ ]] |
|---|---|---|
| Greater Than | (( NUM > 10 )) | [[ "$NUM" -gt 10 ]] |
| Less Than | (( NUM < 5 )) | [[ "$NUM" -lt 5 ]] |
| Equal To | (( NUM == 0 )) | [[ "$NUM" -eq 0 ]] |
| Not Equal To | (( NUM != 1 )) | [[ "$NUM" -ne 1 ]] |
| Greater or Equal | (( NUM >= 8 )) | [[ "$NUM" -ge 8 ]] |
| Less or Equal | (( NUM <= 3 )) | [[ "$NUM" -le 3 ]] |

------------------------------
## 2. Shell Loops Reference## for Loop: Iterating Lists
Perfect for running tasks across multiple items, servers, or file paths.

# Iterating over fixed stringsfor SERVICE in nginx sshd docker; do
    echo "Restarting service: $SERVICE"
    systemctl restart "$SERVICE"done
# Iterating over file lists using wildcardsfor SCRIPT in *.sh; do
    echo "Setting execution flag on: $SCRIPT"
    chmod +x "$SCRIPT"done

## while Loop: Automation & Delays
Runs continuously as long as a specific condition stays true. Highly useful for active loops and countdown timers.

# Loop that runs indefinitely every 60 secondswhile true; do
    if ! systemctl is-active --quiet "nginx"; then
        echo "ALERT: nginx is down! Triggering restart..."
        systemctl start nginx
    fi
    sleep 60done

------------------------------
## 3. Bash Functions Reference
Functions modularize scripts into clean, reusable structural components.
## Defining and Calling Functions

* Do not use parentheses when sending inputs into a function.
* Catch variables inside using numeric placements ($1 for first input, $2 for second).

#!/bin/bash
# Define the utility function
log_message() {
    local LEVEL="$1"
    local MSG="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$LEVEL] - $MSG"
}
# Execute the function with custom inputs
log_message "INFO" "Deployment script initialized successfully."
log_message "ERROR" "Database connection timed out."

## Common Service Status Codes Table
When automating functions, scripts evaluate the hidden exit status codes from background utility calls:

| Utility Action Command | Successful Execution Code | Failure Execution Code |
|---|---|---|
| systemctl is-active | 0 (Service Active) | 3 (Stopped) / 4 (Not Found) |
| ping -c 1 Host | 0 (Host Reachable) | 1 (Host Unreachable) |
| id -u Root Check | 0 (Current Identity is Root) | Non-zero value (Standard User Profile) |

------------------------------
