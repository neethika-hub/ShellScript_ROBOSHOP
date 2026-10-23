#!/bin/bash

user_id=$(id -u)
log_folder=/var/log/roboshop
logfile=$(echo $0 | cut -d '.' -f1)
logfile_name=$log_folder/$logfile.log
echo $logfile_name
time=$(date +%F-%H:%M:%S)
started_time=$(date +%T)
echo "Script started at $started_time"
Validation(){
if [ $1 -ne 0 ]
then
    echo "$2 is FAILED"
    exit 1
else
    echo "$2 is SUCCESS"
fi
}

echo "===========Creating log folder if not exists=========="
mkdir -p $log_folder #-p will create if folder is not present or it will ignore if already present
Validation $? "Creation of logfolder $log_folder"

echo "==========Check if we are running with ROOT==========="
if [ $user_id -ne 0 ]
then
    echo "You are not in ROOT. Please switch to ROOT"
    exit 1
else
    echo "You are in ROOT." | tee -a $logfile_name
fi

echo "===========Copy repo file to repo directory==========="
cp mongo.repo /etc/yum.repos.d/mongo.repo
Validation $? "Placing mongo.repo"

echo "==========Installing mongodb================"
dnf install mongodb-org -y
Validation $? "Installation of mongodb"

echo "=======Starting mongodb================="
systemctl enable mongod
systemctl start mongod
Validation $? "Starting mongodb"

echo "===========Updating listen address============"
cp /etc/mongod.conf /etc/mongod.conf_backup_$time
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
Validation $? "Listen update address"

echo "==========Restart mongodb===================="
systemctl restart mongod
Validation $? "Mongodb restart"

end_time=$(date +%T)
total_time=$(($end_time-$started_time))
echo "Total time taken for the script is $total_time"
