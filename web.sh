#!/bin/bash
USER_ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOG_FILE="/tmp/$0-$TIMESTAMP.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ "$USER_ID" -ne 0 ]
then
    echo -e "${R}Please login as root user${N}"
    exit 1
else
    echo -e "${G}Logged in as Root user${N}"
fi

validate() {
    if [ "$1" -ne 0 ]
    then
        echo -e "$2 ... ${R}FAILED${N}"
        exit 1
    else
        echo -e "$2 ... ${G}SUCCESS${N}"
    fi
}

dnf module disable nginx  -y &>> $LOG_FILE
validate $? "disabled nodejs default version"

dnf module enable nginx:1.24 -y &>> $LOG_FILE
validate $? "Enabled nginx:1.24 version"

dnf install nginx  -y &>> $LOG_FILE
validate $? "Install nginx:1.24 version"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Remove default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloaded  frontend"

cd /usr/share/nginx/html 

unzip /tmp/frontend.zip
VALIDATE $? "Unzipped frontend"

cp /home/ec2-user/roboshop-shell/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copied our nginx conf file"

systemctl restart nginx 
VALIDATE $? "Restarted Nginx"