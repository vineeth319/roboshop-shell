#!/bin/bash

USER_ID=$(id -u)

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(basename "$0")
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

mkdir -p "$LOGS_FOLDER"

# Root user check
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

# Install mysql-server
dnf install mysql-server -y &>> "$LOGS_FILE"
validate $? "Installing mysql-server"

# Enable mysqld service
systemctl enable mysqld &>> "$LOGS_FILE"
validate $? "Enabling mysqld"

# Start mysqld service
systemctl start mysqld &>> "$LOGS_FILE"
validate $? "Starting mysqld"

# Set mysql root password
mysql_secure_installation --set-root-pass RoboShop@1 &>> "$LOGS_FILE"
validate $? "Setting mysql root password"

echo -e "${G}MySQL setup completed successfully${N}" | tee -a "$LOGS_FILE"