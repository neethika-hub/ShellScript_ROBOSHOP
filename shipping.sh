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

echo "Enter Root password"
read -s MySQL_ROOT_PASSWORD

echo "==========Install Maven=================="
dnf install maven -y &>>$LOGFILE_NAME
VALIDATION $? "Installing MAVEN"

echo "===========Create app directory==========="
mkdir -p /app
VALIDATION $? "Creating app directory"

echo "===========Create System user============="
id roboshop | tee -a $LOGFILE_NAME
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop System user" roboshop
    VALIDATION $? "Creating System User"
else
    echo "System User is already Present" | tee -a $LOGFILE_NAME
fi

echo "=================Download and unzip applciation code==============="
cd /app
curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOGFILE_NAME
rm -rf /app/*
cp /tmp/shipping.zip /app
unzip shipping.zip &>>$LOGFILE_NAME
VALIDATION $? "Unzipping of the Application code"
rm -rf *.zip

echo "=================Download dependencies and Build the Application============="
mvn clean package &>>$LOGFILE_NAME
mv /app/target/shipping-1.0.jar /app/shipping.jar
VALIDATION $? "Buidling the Application"

echo "=================Copy the Service file======================"
cp $SCRIPT_PATH/shipping.service /etc/systemd/system/shipping.service
VALIDATION $? "Copying Service file"

echo "=================Enable & Start Application"
systemctl daemon-reload
systemctl enable shipping
systemctl start shipping
VALIDATION $? "Starting Shipping Application"

echo "==============Install MySQL Client to Load the Schema============"
dnf isntall mysql -y &>>$LOGFILE_NAME
VALIDATION $? "MySQL Client Instalaltion"

echo "====================LOAD Data==============================="
mysql -h mysql.shynudevops.shop -uroot -p$MySQL_ROOT_PASSWORD -e 'use cities' | tee -a $LOGFILE_NAME
if [ $? -ne 0 ]
then
    mysql -h mysql.shynudevops.shop -uroot -p$MySQL_ROOT_PASSWORD < /app/db/schema.sql
    mysql -h mysql.shynudevops.shop -uroot -p$MySQL_ROOT_PASSWORD < /app/db/app-user.sql 
    mysql -h mysql.shynudevops.shop -uroot -p$MySQL_ROOT_PASSWORD < /app/db/master-data.sql
    VALIDATION $? "Loading Data"
else
    echo "Data is already Present" | tee -a $LOGFILE_NAME
fi

echo "================Restart Shipping Service============"
systemctl restart shipping
VALIDATION $? "Restarting SHipping Service"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo "Time taken for the script is $TOTAL_TIME ms"