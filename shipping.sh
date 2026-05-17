#!/bin/bash
USER_ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOG_FILE="/tmp/$0-$TIMESTAMP.log"
mysql_host=mysql.vineeth.online
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


dnf install maven -y
validate $? "Install nodejs:20 version"
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
mkdir -p /app

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
cd /app 
unzip -o /tmp/shipping.zip

mvn clean package 
mv target/shipping-1.0.jar shipping.jar 


cp /home/ec2-user/roboshop-shell/shipping.service /etc/systemd/system/shipping.service
validate $? "copy shipping.service"

systemctl daemon-reload &>> $LOG_FILE
validate $? "shipping daemon reload" &>> $LOG_FILE

systemctl enable shipping &>> $LOG_FILE 
validate $? "Enable shipping"

systemctl start shipping &>> $LOG_FILE 
validate $? "Starting shipping"

dnf install mysql -y 
validate $? "Install mysql client"

mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/schema.sql
validate $? "Insert Schema"

mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/app-user.sql 
validate $? "Insert app-user"

mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/master-data.sql
validate $? "Insert master-data"

systemctl restart shipping
validate $? "Restarting shipping"