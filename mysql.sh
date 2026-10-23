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
    echo "$2 is...FAILED" | tee -a $LOGFILE_NAME
    exit 1
else
    echo "$2 is...SUCCESS" | tee -a $LOGFILE_NAME
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

echo "================Install MySQL======================"
dnf install mysql-server -y &>>$LOGFILE_NAME
VALIDATION $? "Installing MySQL"

echo "===============Start MySQL======================="
systemctl enable mysqld
systemctl start mysqld
VALIDATION $? "Starting MySQL"

echo "==============Update Default ROOT password==========="
mysql_secure_installation --set-root-pass RoboShop@1
VALIDATION $? "Updating Root Password"

echo "==============Validate process======================"
PROCESS_ID=$(ps -ef | grep mysqld | grep -v grep | wc -l)
if [ $PROCESS_ID -eq 1 ]
then
    echo "The Process is UP" | tee -a $LOGFILE_NAME
    VALIDATION $? "The Process"
else
    echo "The Process is NOT UP"
fi

echo "===============Validate Logs======================="
ERROR_LOG=$(grep -i "error" /var/log/message | wc -l)
if [ $ERROR_LOG -gt 0 ]
then
    echo "THERE IS A ERROR IN LOGS PLEASE CHECK!!!" | tee -a $LOGFILE_NAME
    echo "MySQL IS NOT STARTED CORRECTLY" | tee -a $LOGFILE_NAME
else
    VALIDATION $? "MySQL Started without errors"
fi

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo "Time taken for the script is $TOTAL_TIME ms"