#!/bin/bash

USER_ID=$(id -u)
# Get script directory
SCRIPT_DIR=$(pwd)

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

# Disable default nodejs module
dnf module disable nodejs -y &>> "$LOGS_FILE"
validate $? "Disable default nodejs"

# Enable nodejs 20
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

# Create application directory
mkdir -p /app &>> "$LOGS_FILE"
validate $? "Create app directory"

# Download cart application code
curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>> "$LOGS_FILE"
validate $? "Download cart application code"

# Change to application directory
cd /app &>> "$LOGS_FILE"
validate $? "Change to app directory"

# Extract application code
unzip -o /tmp/cart.zip &>> "$LOGS_FILE"
validate $? "Extract cart application code"

# Install nodejs dependencies
npm install &>> "$LOGS_FILE"
validate $? "Install nodejs dependencies"


# Copy service file
cp "$SCRIPT_DIR/cart.service" /etc/systemd/system/cart.service &>> "$LOGS_FILE"
validate $? "Copy cart.service"

# Reload systemd
systemctl daemon-reload &>> "$LOGS_FILE"
validate $? "Reload systemd"

# Enable cart service
systemctl enable cart &>> "$LOGS_FILE"
validate $? "Enable cart service"

# Restart cart service
systemctl restart cart &>> "$LOGS_FILE"
validate $? "Restart cart service"

echo -e "${G}Cart service setup completed successfully${N}" | tee -a "$LOGS_FILE"