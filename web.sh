#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ "$USERID" -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nginx  -y &>> $LOGS_FILE
validate $? "disabled nodejs default version"

dnf module enable nginx:1.24 -y &>> $LOGS_FILE
validate $? "Enabled nginx:1.24 version"

dnf install nginx  -y &>> $LOGS_FILE
validate $? "Install nginx:1.24 version"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Remove default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloaded  frontend"

cd /usr/share/nginx/html 

unzip /tmp/frontend.zip
VALIDATE $? "Unzipped frontend"

rm -rf /etc/nginx/nginx.conf
VALIDATE $? "Remove default nginx configuration"

cp /home/ec2-user/roboshop-shell/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copied our nginx conf file"

systemctl restart nginx 
VALIDATE $? "Restarted Nginx"