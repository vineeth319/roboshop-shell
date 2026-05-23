#!/bin/bash

USER_ID=$(id -u)

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(basename "$0")
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
# Get script directory
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
mysql_host=mysql.vineeth.online
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

# Install maven
dnf install maven -y &>> "$LOGS_FILE"
validate $? "Install maven"

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

# Download shipping application
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> "$LOGS_FILE"
validate $? "Download shipping application"

# Change to app directory
cd /app &>> "$LOGS_FILE"
validate $? "Change to app directory"

# Extract application
unzip -o /tmp/shipping.zip &>> "$LOGS_FILE"
validate $? "Extract shipping application"

# Build package
mvn clean package &>> "$LOGS_FILE"
validate $? "Build shipping package"

# Rename jar
mv target/shipping-1.0.jar shipping.jar &>> "$LOGS_FILE"
validate $? "Rename shipping jar"



# Copy service file
cp "$SCRIPT_DIR/shipping.service" /etc/systemd/system/shipping.service &>> "$LOGS_FILE"
validate $? "Copy shipping.service"

# Reload systemd
systemctl daemon-reload &>> "$LOGS_FILE"
validate $? "Reload systemd"

# Enable shipping service
systemctl enable shipping &>> "$LOGS_FILE"
validate $? "Enable shipping service"

# Start shipping service
systemctl start shipping &>> "$LOGS_FILE"
validate $? "Start shipping service"

# Install mysql client
dnf install mysql -y &>> "$LOGS_FILE"
validate $? "Install mysql client"

# Load schema
mysql -h "$mysql_host" -uroot -pRoboShop@1 < /app/db/schema.sql &>> "$LOGS_FILE"
validate $? "Load schema"

# Load app-user data
mysql -h "$mysql_host" -uroot -pRoboShop@1 < /app/db/app-user.sql &>> "$LOGS_FILE"
validate $? "Load app-user data"

# Load master-data
mysql -h "$mysql_host" -uroot -pRoboShop@1 < /app/db/master-data.sql &>> "$LOGS_FILE"
validate $? "Load master-data"

# Restart shipping service
systemctl restart shipping &>> "$LOGS_FILE"
validate $? "Restart shipping service"

echo -e "${G}Shipping setup completed successfully${N}" | tee -a "$LOGS_FILE"