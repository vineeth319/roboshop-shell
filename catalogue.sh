#!/bin/bash
USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
MONGODB_HOST=mongodb.vineeth.online
SCRIPT_DIR=$(pwd)

mkdir -p $LOGS_FOLDER

if [ "$USER_ID" -ne 0 ]; then
    echo -e "${R}Please login as root user${N}" | tee -a $LOGS_FILE
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

dnf module disable nodejs -y &>> $LOGS_FILE
validate $? "disabled nodejs default version"

dnf module enable nodejs:20 -y &>> $LOGS_FILE
validate $? "Enabled nodejs:20 version"

dnf install nodejs -y &>> $LOGS_FILE
validate $? "Install nodejs:20 version"

id roboshop &>> $LOGS_FILE #if roboshop user does not exist, then it is failure
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
    validate $? "create roboshop system user"
else
    echo -e "roboshop user already exist $Y SKIPPING $N"
fi


mkdir -p /app &>> $LOGS_FILE
validate $? "create app dir"

curl -L -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOGS_FILE
validate $? "download catalogue code"

cd /app

unzip -o /tmp/catalogue.zip &>> $LOGS_FILE
validate $? "unzip catalogue code"

npm install  &>> $LOGS_FILE
validate $? "install dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
validate $? "copy catalogue.service"

systemctl daemon-reload &>> $LOGS_FILE

validate $? "catalogue daemon reload" &>> $LOGS_FILE

systemctl enable catalogue &>> $LOGS_FILE 

validate $? "Enable catalogue"

systemctl start catalogue &>> $LOGS_FILE 

validate $? "Starting catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGS_FILE

validate $? "copying mongodb repo"

dnf install mongodb-mongosh -y &>> $LOGS_FILE

validate $? "Installing MongoDB client"
INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js
    validate $? "Loading products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue"