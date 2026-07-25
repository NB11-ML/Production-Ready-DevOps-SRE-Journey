#! /bin/bash
#Shell script solution to setup logs

mkdir -p /tmp/app_logs/archive/
touch /tmp/app_logs/{access.log,error.log,system.log}

chmod 700 /tmp/app_logs
chmod 640 /tmp/app_logs/*.log

echo "Log environment created on $(date)" > /tmp/app_logs/setup.log
echo "Directory and file permissions successfully set."  
