#!/bin/bash

USER_ID=$(id -u)

SCRIPT_NAME=$(basename "$0")

LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

mkdir -p "$LOGS_FOLDER"

# Root user validation
if [ "$USER_ID" -ne 0 ]
then
    echo -e "${R}Please run this script with root user access${N}" | tee -a "$LOGS_FILE"
    exit 1
fi

# Validation function
validate() {
    if [ "$1" -ne 0 ]
    then
        echo -e "$2 ... ${R}FAILED${N}" | tee -a "$LOGS_FILE"
        exit 1
    else
        echo -e "$2 ... ${G}SUCCESS${N}" | tee -a "$LOGS_FILE"
    fi
}

echo "Script execution started at: $(date)" | tee -a "$LOGS_FILE"

# Copy rabbitmq repo file
cp /home/ec2-user/roboshop-shell/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> "$LOGS_FILE"
validate $? "Copy rabbitmq repo"

# Install rabbitmq-server
dnf install rabbitmq-server -y &>> "$LOGS_FILE"
validate $? "Install RabbitMQ"

# Enable rabbitmq-server
systemctl enable rabbitmq-server &>> "$LOGS_FILE"
validate $? "Enable RabbitMQ"

# Start rabbitmq-server
systemctl start rabbitmq-server &>> "$LOGS_FILE"
validate $? "Start RabbitMQ"

# Check if roboshop user already exists
rabbitmqctl list_users | grep roboshop &>> "$LOGS_FILE"

if [ $? -ne 0 ]
then
    rabbitmqctl add_user roboshop roboshop123 &>> "$LOGS_FILE"
    validate $? "Add RabbitMQ user"
else
    echo -e "RabbitMQ user already exists ... ${Y}SKIPPING${N}" | tee -a "$LOGS_FILE"
fi

# Set permissions
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> "$LOGS_FILE"
validate $? "Set permissions for RabbitMQ user"

echo -e "${G}RabbitMQ setup completed successfully${N}" | tee -a "$LOGS_FILE"