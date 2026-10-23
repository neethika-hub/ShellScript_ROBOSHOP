#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER=/var/log/roboshop
FILE_NAME=$(echo $0 | cut -d '.' -f1)
LOG_FILENAME=$LOG_FOLDER/$FILE_NAME.log
START_TIME=$(date +%S)
TIME=$(date +%F-%H:%M:%S)
SCRIPT_PATH=$PWD
