#!/bin/bash

USER_ID=$(id -u)
# Get script directory
SCRIPT_DIR=$(pwd)
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

# Install nginx
dnf install nginx -y &>> "$LOGS_FILE"
validate $? "Install nginx"

# Enable nginx
systemctl enable nginx &>> "$LOGS_FILE"
validate $? "Enable nginx"

# Start nginx
systemctl start nginx &>> "$LOGS_FILE"
validate $? "Start nginx"

# Remove default nginx content
rm -rf /usr/share/nginx/html/* &>> "$LOGS_FILE"
validate $? "Remove default nginx content"

# Download frontend application
curl -L -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> "$LOGS_FILE"
validate $? "Download frontend application"

# Change to nginx html directory
cd /usr/share/nginx/html &>> "$LOGS_FILE"
validate $? "Change to nginx html directory"

# Extract frontend application
unzip -o /tmp/frontend.zip &>> "$LOGS_FILE"
validate $? "Extract frontend application"



# Copy nginx configuration
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copied our nginx conf file"

# Restart nginx
systemctl restart nginx &>> "$LOGS_FILE"
validate $? "Restart nginx"

echo -e "${G}Frontend setup completed successfully${N}" | tee -a "$LOGS_FILE"