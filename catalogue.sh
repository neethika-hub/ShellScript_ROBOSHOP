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
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip
cd /app
rm -rf /app/*
cp /tmp/catalogue.zip /app
unzip catalogue.zip &>>$LOGFILE_NAME
VALIDATION $? "Downloaded and unzipped Catalogue application code"
rm -rf catalogue.zip

echo "=================Download NODEJS Dependencies============================"
npm install &>>$LOGFILE_NAME
VALIDATION $? "Downloading NODEJS Dependencies"

echo "==================Copy catalogue service file======================="
cp $SCRIPT_PATH/catalogue.service /etc/systemd/system/catalogue.service
VALIDATION $? "Copying catalogue service file"

echo "=============Start catalogue service========================="
systemctl daemon-reload
systemctl enable catalogue
systemctl start catalogue
VALIDATION $? "Starting catalogue"

echo "=============Copy mongodb repo======================"
cp $SCRIPT_PATH/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATION $? "Copying mongodb repo"

echo "==============Install mongodb client================="
dnf install mongodb-mongosh -y &>>$LOGFILE_NAME
VALIDATION $? "Installing mongodb client"

echo "===============Load Master Data====================="
STATUS=$(mongosh --host mongodb.shynudevops.shop --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.shynudevops.shop < /app/db/master-data.js &>>$LOG_FILENAME
    VALIDATION $? "Loading Data into mongodb"
else
    echo "Data is already loaded" | tee -a $LOG_FILENAME
fi

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo "Time taken for the script is $TOTAL_TIME ms"
