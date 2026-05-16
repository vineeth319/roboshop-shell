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
    else
        echo -e "$2 ... ${G}SUCCESS${N}"
    fi
}


dnf module disable redis -y &>> $LOG_FILE
VALIDATE $? "disable redis"
dnf module enable redis:7 -y &>> $LOG_FILE
VALIDATE $? "enable redis:7"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf &>> $LOG_FILE
VALIDATE $? "change local host to all hosts"
sed -i 's/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf &>> $LOG_FILE
VALIDATE $? "change protected-mode from yet to no"
systemctl enable redis &>> $LOG_FILE
VALIDATE $? "enable redis at boot time"
systemctl start redis &>> $LOG_FILE
VALIDATE $? "Starting redis"