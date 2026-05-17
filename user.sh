#!/bin/bash

USER_ID=$(id -u)

SCRIPT_NAME=$(basename "$0")

LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

# Get script directory
SCRIPT_DIR=$(pwd)

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

# Disable default nodejs
dnf module disable nodejs -y &>> "$LOGS_FILE"
validate $? "Disable default nodejs"

# Enable nodejs:20
dnf module enable nodejs:20 -y &>> "$LOGS_FILE"
validate $? "Enable nodejs:20"

# Install nodejs
dnf install nodejs -y &>> "$LOGS_FILE"
validate $? "Install nodejs"

# Create roboshop user if not exists
if ! id roboshop &>> "$LOGS_FILE"
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> "$LOGS_FILE"
    validate $? "Create roboshop user"
else
    echo -e "roboshop user already exists ... ${Y}SKIPPING${N}" | tee -a "$LOGS_FILE"
fi

# Create app directory
mkdir -p /app &>> "$LOGS_FILE"
validate $? "Create app directory"

# Download user application
curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>> "$LOGS_FILE"
validate $? "Download user application"

# Change to app directory
cd /app &>> "$LOGS_FILE"
validate $? "Change to app directory"

# Extract application
unzip -o /tmp/user.zip &>> "$LOGS_FILE"
validate $? "Extract user application"

# Install nodejs dependencies
npm install &>> "$LOGS_FILE"
validate $? "Install nodejs dependencies"



# Copy user service file
cp "$SCRIPT_DIR/user.service" /etc/systemd/system/user.service &>> "$LOGS_FILE"
validate $? "Copy user.service"

# Reload systemd
systemctl daemon-reload &>> "$LOGS_FILE"
validate $? "Reload systemd"

# Enable user service
systemctl enable user &>> "$LOGS_FILE"
validate $? "Enable user service"

# Restart user service
systemctl restart user &>> "$LOGS_FILE"
validate $? "Restart user service"

echo -e "${G}User setup completed successfully${N}" | tee -a "$LOGS_FILE"