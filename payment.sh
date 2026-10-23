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

echo "===============Install Python================="
dnf install python3 gcc python3-devel -y &>>$LOGFILE_NAME
VALIDATION $? "Installing Python"

echo "===========Create app directory==========="
mkdir -p /app
VALIDATION $? "Creating app directory"

echo "===========Create System user============="
id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop System user" roboshop
    VALIDATION $? "Creating System User"
else
    echo "System User is already Present" | tee -a $LOGFILE_NAME
fi

echo "============Download application code to the created app directory=================="
curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$LOGFILE_NAME
cd /app
rm -rf /app/*
cp /tmp/payment.zip /app
unzip payment.zip &>>$LOGFILE_NAME
VALIDATION $? "Downloaded and unzipped Payment application code"
rm -rf *.zip

echo "===============Download Dependencies===================="
cd /app
pip3 install -r requirements.txt &>>$LOGFILE_NAME
VALIDATION $? "Downloading Dependencies"

echo "=================Copy Payment service file============"
cp $SCRIPT_PATH/payment.service /etc/systemd/system/payment.service
VALIDATION $? "Copying Payment Service file"

echo "=============Start payment Application==========="
systemctl daemon-reload
systemctl enable payment
systemctl start payment
VALIDATION $? "Starting Payment Application"

echo "==============Validate process======================"
PROCESS_ID=$(ps -ef | grep /app/payment.ini | grep -v grep | wc -l)
if [ $PROCESS_ID -eq 1 ]
then
    echo "The Process is UP" | tee -a $LOGFILE_NAME
    VALIDATION $? "The Application Process"
else
    echo "The Process is NOT UP" | tee -a $LOGFILE_NAME
fi

echo "===============Validate Logs======================="
ERROR_LOG=$(grep -i "error" /var/log/message | wc -l)
if [ $ERROR_LOG -gt 0 ]
then
    echo "THERE IS A ERROR IN LOGS PLEASE CHECK!!!" | tee -a $LOGFILE_NAME
    echo "APPLCIATION IS NOT STARTED CORRECTLY" | tee -a $LOGFILE_NAME
else
    VALIDATION $? "Application Started without errors"
fi

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo "Time taken for the script is $TOTAL_TIME ms"
