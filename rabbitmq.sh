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

cp /home/ec2-user/roboshop-shell/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "Copied rabbitmq Repo"

dnf install rabbitmq-server -y
validate $? "Insatll RabbitMQ"

systemctl enable rabbitmq-server 
validate $? "Enabled RabbitMQ"

systemctl start rabbitmq-server 
validate $? "Start of RabbitMQ"


rabbitmqctl add_user roboshop roboshop123
validate $? "Add RabbitMQ User"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
validate $? "All previliges to  RabbitMQ roboshop User"