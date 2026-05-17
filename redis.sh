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

if [ "$USER_ID" -ne 0 ]; then
    echo -e "${R}Please run this script with root user access${N}" | tee -a "$LOGS_FILE"
    exit 1
fi

validate() {
    if [ "$1" -ne 0 ]; then
        echo -e "$2 ... ${R}FAILED${N}" | tee -a "$LOGS_FILE"
        exit 1
    else
        echo -e "$2 ... ${G}SUCCESS${N}" | tee -a "$LOGS_FILE"
    fi
}

dnf module disable redis -y &>> "$LOGS_FILE"
validate $? "Disable default redis"

dnf module enable redis:7 -y &>> "$LOGS_FILE"
validate $? "Enable redis:7"

dnf install redis -y &>> "$LOGS_FILE"
validate $? "Install redis"

sed -i \
-e 's/127.0.0.1/0.0.0.0/g' \
-e '/protected-mode/ c protected-mode no' \
/etc/redis/redis.conf &>> "$LOGS_FILE"

validate $? "Allow remote redis connections"

systemctl enable redis &>> "$LOGS_FILE"
validate $? "Enable redis service"

systemctl start redis &>> "$LOGS_FILE"
validate $? "Start redis service"

echo -e "${G}Redis setup completed successfully${N}" | tee -a "$LOGS_FILE"