#!/bin/bash
LOG_FILE="/tmp/$0-$TIMESTAMP.log"
USER_ID=$(id -u) &>> $LOG_FILE
TIMESTAMP=$(date +%F-%H-%M-%S)
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

id roboshop #if roboshop user does not exist, then it is failure
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
    validate $? "create roboshop system user"
else
    echo -e "roboshop user already exist $Y SKIPPING $N"
fi


mkdir -p /app &>> $LOG_FILE
validate $? "create app dir"

curl -L -o  /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>> $LOG_FILE
validate $? "download cart code"
cd /app
unzip -o /tmp/cart.zip &>> $LOG_FILE
validate $? "unzip cart code"

npm install  &>> $LOG_FILE
validate $? "install dependencies"

cp /home/ec2-cart/roboshop-shell/cart.service /etc/systemd/system/cart.service
validate $? "copy cart.service"

systemctl daemon-reload &>> $LOG_FILE

validate $? "cart daemon reload" &>> $LOG_FILE

systemctl enable cart &>> $LOG_FILE 

validate $? "Enable cart"

systemctl start cart &>> $LOG_FILE 

validate $? "Starting cart"