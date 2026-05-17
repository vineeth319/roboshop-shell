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

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>> $LOGS_FILE
validate $? "download user code"
cd /app

unzip -o /tmp/user.zip &>> $LOGS_FILE
validate $? "unzip user code"

npm install  &>> $LOGS_FILE
validate $? "install dependencies"

cp /home/ec2-user/roboshop-shell/user.service /etc/systemd/system/user.service
validate $? "copy user.service"

systemctl daemon-reload &>> $LOGS_FILE

validate $? "user daemon reload" &>> $LOGS_FILE

systemctl enable user &>> $LOGS_FILE 

validate $? "Enable user"

systemctl start user &>> $LOGS_FILE 

validate $? "Starting user"