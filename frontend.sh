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

echo "============Disable default NGINX==============="
dnf module disable nginx -y &>>$LOGFILE_NAME
VALIDATION $? "Disbaling Default NGINX"

echo "==============Enable NGINX 1.24================="
dnf module enable nginx:1.24 -y &>>$LOGFILE_NAME
VALIDATION $? "Enabling 1.24 NGINX"

echo "==============Install NGINX==================="
dnf install nginx -y &>>$LOGFILE_NAME
VALIDATION $? "Installaing NGINX"

echo "==============start NGINX=================="
systemctl enable nginx
systemctl start nginx

echo "===============Download Frontend Application code and UNZIP=================="
cd /usr/share/nginx/html
rm -rf /usr/share/nginx/html/*
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOGFILE_NAME
cp /tmp/frontend.zip /usr/share/nginx/html
unzip frontend.zip &>>$LOGFILE_NAME
VALIDATION $? "Downloading and Unzipping"
rm -rf /usr/share/nginx/html/frontend.zip

echo "================Copy nginx configuration============"
cp $SCRIPT_PATH/nginx.conf /etc/nginx/nginx.conf
VALIDATION $? "Copying nginx conf file"

echo "===============Restart NGINX==================="
systemctl restart nginx
VALIDATION $? "Restarting nginx"

echo "==============Validate process======================"
PROCESS_ID=$(ps -ef | grep "nginx:master" | grep -v grep | wc -l)
if [ $PROCESS_ID -eq 1 ]
then
    echo "The Process is UP" | tee -a $LOGFILE_NAME
    VALIDATION $? "The Application Process"
else
    echo "The Process is NOT UP"
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