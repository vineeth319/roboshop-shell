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

cp /home/ec2-user/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Copied MongoDB Repo"

dnf install mongodb-org -y &>> $LOG_FILE
validate $? "Insatll mongodb"

systemctl enable mongod 
validate $? "Enabled mongodb"

systemctl start mongod 
validate $? "Start of mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> $LOG_FILE
validate $? "Remote access to MongoDB"

systemctl restart mongod &>> $LOG_FILE
validate $? "Restarting MongoDB"