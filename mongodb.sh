#!/bin/bash

user_id=$(id -u)
log_folder=/var/log/roboshop
logfile=$(echo $0 | cut -d '.' f1)
logfile_name=$log_folder/$logfile.log

echo "Creating log folder if not exists"
mkdir -p $log_folder #-p will create if folder is not present or it will ignore if already present

echo "check if we are running with ROOT"
if [ $user_id -ne 0 ]
then
    echo "You are not in ROOT. Please switch to ROOT"
    exit 1
else
    echo "You are in ROOT."
fi
