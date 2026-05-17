#!/bin/bash
USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

mkdir -p $LOGS_FOLDER

if [ "$USERID" -ne 0 ]; then
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

cp /home/ec2-user/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Copied MongoDB Repo"

dnf install mongodb-org -y &>> $LOGS_FILE
validate $? "Insatll mongodb"

systemctl enable mongod &>> $LOGS_FILE
validate $? "Enabled mongodb"

systemctl start mongod 
validate $? "Start of mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> $LOGS_FILE
validate $? "Remote access to MongoDB"

systemctl restart mongod &>> $LOGS_FILE
validate $? "Restart of MongoDB"