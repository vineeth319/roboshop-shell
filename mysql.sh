USER_ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOG_FILE="/tmp/$0-$TIMESTAMP.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

exec &>> LOG_FILE
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

dnf install mysql-server -y
validate $? " Installing mysql"

systemctl enable mysqld
validate $? " Enabling mysql"

systemctl start mysqld  
validate $? " Starting mysql"

mysql_secure_installation --set-root-pass RoboShop@1
validate $? "Set Root password"