#!/bin/bash
# Description: Comprehensive System Information Reporter

set -euo pipefail

print_os_info(){
    echo "=== 🖥️  Hostname & OS Info ==="
    echo "Hostname: $(hostname)"
    #Extract PRETTY_NAME from os-release to get a clean os string
    grep "^PRETTY_NAME"= /etc/os-release | cut -d '"' -f 2 
    echo ""
}

print_uptime(){
    echo "=== ⏱️  System Uptime ==="
    uptime -p
    echo ""
}

print_disk_usage(){
    echo "=== 💾 Top 5 Disk Partitions (By Size) ==="
    # Print header, then sort by size (column 2) in reverse human-readable format
    df -h | head -n 1
    df -h | sed '1d' | sort -hr -k 2 | head -n 5
    echo ""
}
print_memory(){
    echo "=== 🧠 Memory Usage ==="
    free -h
    echo ""    
}

print_top_cpu() {
    echo "=== 🔥 Top 5 CPU-Consuming Processes ==="
    # Show PID, User, %CPU, %MEM, and Command, sorted by %CPU
    ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 6
    echo ""
}
main() {
    echo "========================================="
    echo "       SYSTEM INFORMATION REPORT         "
    echo "       Generated: $(date +'%Y-%m-%d')      "
    echo "========================================="
    echo ""
    
    print_os_info
    print_uptime
    print_disk_usage
    print_memory
    print_top_cpu
    
    echo "========================================="
    echo "          REPORT COMPLETE                "
    echo "========================================="
}
# Execute Main Block
main