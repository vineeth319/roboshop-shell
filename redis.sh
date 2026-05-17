#!/bin/bash
USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

mkdir -p $LOGS_FOLDER

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

validate() {
    if [ "$1" -ne 0 ]
    then
        echo -e "$2 ... ${R}FAILED${N}" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... ${G}SUCCESS${N}" | tee -a $LOGS_FILE
    fi
}


dnf module disable redis -y &>> $LOGS_FILE
validate $? "disable redis"

dnf module enable redis:7 -y &>> $LOGS_FILE
validate $? "enable redis:7"

dnf install redis -y 
validate $? "Install redis:7"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connections"

systemctl enable redis &>> $LOGS_FILE
validate $? "enable redis at boot time"

systemctl start redis &>> $LOGS_FILE
validate $? "Starting redis"