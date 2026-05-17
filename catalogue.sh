#!/bin/bash

USER_ID=$(id -u)

SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

MONGODB_HOST="mongodb.vineeth.online"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

mkdir -p "$LOGS_FOLDER"

# Root user validation
if [ "$USER_ID" -ne 0 ]
then
    echo -e "${R}Please login as root user${N}" | tee -a "$LOGS_FILE"
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

echo "Script started executing at: $(date)" | tee -a "$LOGS_FILE"

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
    useradd --system \
            --home /app \
            --shell /sbin/nologin \
            --comment "roboshop system user" \
            roboshop &>> "$LOGS_FILE"

    validate $? "Create roboshop user"
else
    echo -e "roboshop user already exists ... ${Y}SKIPPING${N}" | tee -a "$LOGS_FILE"
fi

# Create app directory
mkdir -p /app &>> "$LOGS_FILE"
validate $? "Create app directory"

# Download catalogue application
curl -L -o /tmp/catalogue.zip \
https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip \
&>> "$LOGS_FILE"

validate $? "Download catalogue application"

# Change to app directory
cd /app &>> "$LOGS_FILE"
validate $? "Change to app directory"

# Extract catalogue application
unzip -o /tmp/catalogue.zip &>> "$LOGS_FILE"
validate $? "Extract catalogue application"

# Install nodejs dependencies
npm install &>> "$LOGS_FILE"
validate $? "Install nodejs dependencies"

# Copy catalogue service
cp "$SCRIPT_DIR/catalogue.service" \
/etc/systemd/system/catalogue.service \
&>> "$LOGS_FILE"

validate $? "Copy catalogue service"

# Copy MongoDB repo
cp "$SCRIPT_DIR/mongo.repo" \
/etc/yum.repos.d/mongo.repo \
&>> "$LOGS_FILE"

validate $? "Copy MongoDB repo"

# Install MongoDB client
dnf install mongodb-mongosh -y &>> "$LOGS_FILE"
validate $? "Install MongoDB client"

# Check if catalogue database already exists
INDEX=$(mongosh --host "$MONGODB_HOST" \
        --quiet \
        --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ "$INDEX" -lt 0 ]
then
    mongosh --host "$MONGODB_HOST" \
    < /app/db/master-data.js \
    &>> "$LOGS_FILE"

    validate $? "Load catalogue data"
else
    echo -e "Catalogue data already exists ... ${Y}SKIPPING${N}" | tee -a "$LOGS_FILE"
fi

# Reload systemd
systemctl daemon-reload &>> "$LOGS_FILE"
validate $? "Reload systemd"

# Enable catalogue service
systemctl enable catalogue &>> "$LOGS_FILE"
validate $? "Enable catalogue service"

# Restart catalogue service
systemctl restart catalogue &>> "$LOGS_FILE"
validate $? "Restart catalogue service"

echo -e "${G}Catalogue setup completed successfully${N}" | tee -a "$LOGS_FILE"