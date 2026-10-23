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

echo "===========Disable default nodejs============="
dnf module disable nodejs -y &>>$LOGFILE_NAME
VALIDATION $? "Disabling defalut nodejs"

echo "===========Enable NODEJS 20==============="
dnf module enable nodejs:20 -y &>>$LOGFILE_NAME
VALIDATION $? "Enabling nodejs 20"

echo "===========Install nodejs==============="
dnf install nodejs -y &>>$LOGFILE_NAME
VALIDATION $? "Installing nodejs 20"

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
curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOGFILE_NAME
cd /app
rm -rf /app/*
cp /tmp/cart.zip /app
unzip cart.zip &>>$LOGFILE_NAME
VALIDATION $? "Downloaded and unzipped Cart application code"
rm -rf *.zip

echo "=================Download NODEJS Dependencies============================"
npm install &>>$LOGFILE_NAME
VALIDATION $? "Downloading NODEJS Dependencies"

echo "==============Copy CART Service file======================="
cp $SCRIPT_PATH/cart.service /etc/systemd/system/cart.service
VALIDATION $? "Copying CART Service file"

echo "=============Load-enable-start CART======================="
systemctl daemon-reload
systemctl enable cart
systemctl start cart
VALIDATION $? "Starting cart Service"

echo "==============Validate process======================"
PROCESS_ID=$(ps -ef | grep /app/server.js | grep -v grep | wc -l)
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