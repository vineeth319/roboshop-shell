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

# Install python dependencies
dnf install python3 gcc python3-devel -y &>> "$LOGS_FILE"
validate $? "Install Python dependencies"

# Check roboshop user
if ! id roboshop &>> "$LOGS_FILE"
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> "$LOGS_FILE"
    validate $? "Create roboshop system user"
else
    echo -e "roboshop user already exists ... ${Y}SKIPPING${N}" | tee -a "$LOGS_FILE"
fi

# Create app directory
mkdir -p /app &>> "$LOGS_FILE"
validate $? "Create app directory"

# Download payment application
curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>> "$LOGS_FILE"
validate $? "Download payment application"

# Change to app directory
cd /app &>> "$LOGS_FILE"
validate $? "Change to app directory"

# Extract payment application
unzip -o /tmp/payment.zip &>> "$LOGS_FILE"
validate $? "Extract payment application"

# Install python dependencies
pip3 install -r requirements.txt &>> "$LOGS_FILE"
validate $? "Install Python dependencies for payment"

# Get script directory
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Copy payment service file
cp "$SCRIPT_DIR/payment.service" /etc/systemd/system/payment.service &>> "$LOGS_FILE"
validate $? "Copy payment.service"

# Reload systemd
systemctl daemon-reload &>> "$LOGS_FILE"
validate $? "Reload systemd"

# Enable payment service
systemctl enable payment &>> "$LOGS_FILE"
validate $? "Enable payment service"

# Start payment service
systemctl restart payment &>> "$LOGS_FILE"
validate $? "Start payment service"

echo -e "${G}Payment setup completed successfully${N}" | tee -a "$LOGS_FILE"