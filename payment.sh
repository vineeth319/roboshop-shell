#!/bin/bash
USER_ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOG_FILE="/tmp/$0-$TIMESTAMP.log"
mysql_host=mysql.vineeth.online
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
exec &>> LOG_FILE
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


dnf install python36 gcc python3-devel -y

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

curl -o -L /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>> $LOG_FILE
validate $? "download user code"

cd /app
unzip -o /tmp/payment.zip &>> $LOG_FILE
validate $? "payment user code"

pip3.6 install -r requirements.txt
validate $? "install dependencies"

cp /home/ec2-user/roboshop-shell/payment.service /etc/systemd/system/user.service
validate $? "copy user.service"

systemctl daemon-reload &>> $LOG_FILE
validate $? "user daemon reload" &>> $LOG_FILE

systemctl enable user &>> $LOG_FILE 
validate $? "Enable user"

systemctl start user &>> $LOG_FILE 
validate $? "Starting user"