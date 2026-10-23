#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER=/var/log/roboshop
FILE_NAME=$(echo $0 | cut -d '.' -f1)
LOGFILE_NAME=$LOG_FOLDER/$FILE_NAME.log
TIME=$(date +%F-%H:%M:%S)
SCRIPT_PATH=$PWD
START_TIME=$(date +%s)
echo "Script started at $START_TIME"

mkdir -p $LOG_FOLDER #-p will create if folder is not present or it will ignore if already present


VALIDATION(){
if [ $1 -ne 0 ]
then
    echo "$2 is FAILED" | tee -a $LOGFILE_NAME
    exit 1
else
    echo "$2 is SUCCESS" | tee -a $LOGFILE_NAME
fi
}

echo "==========Check if we are running with ROOT==========="
if [ $USER_ID -ne 0 ]
then
    echo "You are not in ROOT. Please switch to ROOT" | tee -a $LOGFILE_NAME
    exit 1
else
    echo "You are in ROOT." | tee -a $LOGFILE_NAME
fi

echo "=============Disable default redis===================="
dnf module disable redis -y 
VALIDATION $? "Disbaling default redis"

echo "=============Enable redis version 7==================="
dnf module enable redis:7 -y
VALIDATION $? "Enabling redis version 7"

echo "===========Install redis==================="
dnf install redis -y 
VALIDATION $? "Installing redis"

echo "===========Update redis configuration file========"
cd /etc/redis
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf
VALIDATION $? "Updating redis configuration file"