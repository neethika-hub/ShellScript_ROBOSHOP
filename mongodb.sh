#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER=/var/log/roboshop
LOGFILE=$(echo $0 | cut -d '.' -f1)
LOGFILE_NAME=$LOG_FOLDER/$LOGFILE.log
echo $LOGFILE_NAME
SCRIPT_PATH=$PWD
TIME=$(date +%F-%H:%M:%S)
START_TIME=$(date +%s)
echo "Script started at $START_TIME"
Validation(){
if [ $1 -ne 0 ]
then
    echo "$2 is FAILED" | tee -a $LOGFILE_NAME
    exit 1
else
    echo "$2 is SUCCESS" | tee -a $LOGFILE_NAME
fi
}

echo "===========Creating log folder if not exists=========="
mkdir -p $LOG_FOLDER #-p will create if folder is not present or it will ignore if already present
Validation $? "Creation of logfolder $LOG_FOLDER"

echo "==========Check if we are running with ROOT==========="
if [ $USER_ID -ne 0 ]
then
    echo "You are not in ROOT. Please switch to ROOT" | tee -a $LOGFILE_NAME
    exit 1
else
    echo "You are in ROOT." | tee -a $LOGFILE_NAME
fi

echo "===========Copy repo file to repo directory==========="
cp $SCRIPT_PATH/mongo.repo /etc/yum.repos.d/mongo.repo
Validation $? "Placing mongo.repo"

echo "==========Installing mongodb================"
dnf install mongodb-org -y &>>$LOGFILE_NAME
Validation $? "Installation of mongodb"

echo "=======Starting mongodb================="
systemctl enable mongod
systemctl start mongod
Validation $? "Starting mongodb"

echo "===========Updating listen address============"
cp /etc/mongod.conf /etc/mongod.conf_backup_$TIME
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
Validation $? "Listen update address"

echo "==========Restart mongodb===================="
systemctl restart mongod
Validation $? "Mongodb restart"

END_TIME=$(date +%s)
echo "$END_TIME"
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo "Total time taken for the script is $TOTAL_TIME ms" | tee -a $LOGFILE_NAME
