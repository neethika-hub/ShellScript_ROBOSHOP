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

echo "Enter Rabbitmq password"
read -s Rabbitmq_PAssword

echo "========Copy RabbitMQ Repo=============="
cp $SCRIPT_PATH/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATION $? "Copying RabbitMQ Repo"

echo "===========Install RabbitMQ================"
dnf install rabbitmq-server -y &>>$LOGFILE_NAME
VALIDATION $? "Installing RabbitMQ"

echo "============Start RabbitMQ==============="
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
VALIDATION $? "Starting Rabbitmq"

echo "===========Create Application user============"
rabbitmqctl add_user roboshop $Rabbitmq_PAssword
VALIDATION $? "Adding User"
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATION $? "Updating Permissions"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo "Time taken for the script is $TOTAL_TIME ms"