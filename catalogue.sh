#!/bin/bash
USER_ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOG_FILE="/tmp/$0-$TIMESTAMP.log"
MONGDB_HOST=18.215.155.33
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

dnf module disable nodejs -y &>> $LOG_FILE
validate $? "disabled nodejs default version"

dnf module enable nodejs:20 -y &>> $LOG_FILE
validate $? "Enabled nodejs:20 version"

dnf install nodejs -y &>> $LOG_FILE
validate $? "Install nodejs:20 version"

id roboshop &>> $LOG_FILE #if roboshop user does not exist, then it is failure
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
    validate $? "create roboshop system user"
else
    echo -e "roboshop user already exist $Y SKIPPING $N"
fi


mkdir -p /app &>> $LOG_FILE
validate $? "create app dir"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOG_FILE
validate $? "download catalogue code"
cd /app
unzip -o /tmp/catalogue.zip &>> $LOG_FILE
validate $? "unzip catalogue code"

npm install  &>> $LOG_FILE
validate $? "install dependencies"

cp /home/ec2-user/roboshop-shell/catalogue.service /etc/systemd/system/catalogue.service
validate $? "copy catalogue.service"

systemctl daemon-reload &>> $LOG_FILE

validate $? "catalogue daemon reload" &>> $LOG_FILE

systemctl enable catalogue &>> $LOG_FILE 

validate $? "Enable catalogue"

systemctl start catalogue &>> $LOG_FILE 

validate $? "Starting catalogue"

cp /home/ec2-user/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOG_FILE

validate $? "copying mongodb repo"

dnf install mongodb-mongosh -y

validate $? "Installing MongoDB client"

mongosh --host mongodb.vineeth.online </app/db/master-data.js &>> $LOG_FILE
validate $? "Loading catalouge data into MongoDB"
