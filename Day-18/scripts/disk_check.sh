#!/bin/bash
# Description: Modular system checks using functions

check_disk(){
    df -h /

}
check_memory(){
    free -h
}

echo -e "\n++++++++++ Storage Details of Server +++++++++++\n"

check_disk

echo -e "\n++++++++++++ Memory usage of Server ++++++++++++\n"
check_memory