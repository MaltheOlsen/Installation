#!/bin/bash

handle_error() {
    echo -e "\e[31mError: $1\e[0m"
    exit 1
}
check_or_install_app() {
    local cmd=$1
    local app=$2
    local install_cmd=$3

    echo -e "\e[34mChecking if $app is installed...\e[0m"
    if command -v $cmd &> /dev/null; then
        echo -e "\e[32m$app is installed\e[0m"
    else
        echo -e "\e[33m$app is not installed.\e[0m"
        while true; do
            read -p "Do you want to install $app? [Y/n]: " yn
            yn=${yn:-Y}
            case $yn in
                [Yy]* )
                    echo -e "\e[34mInstalling $app...\e[0m"
                    eval $install_cmd || handle_error "Failed to install $app"
                    echo -e "\e[32m$app installed successfully!\e[0m"
                    break
                    ;;
                [Nn]* )
                    echo -e "\e[31m$app will not be installed. Exiting...\e[0m"
                    exit 1
                    ;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}
echo -e "\e[34mUpdating and upgrading the system...\e[0m"
sudo apt-get update -y && sudo apt-get upgrade -y || handle_error "System update/upgrade failed."

check_or_install_app "mariadb" "mariadb" "sudo apt install mariadb-server -y"
sudo mariadb-secure-installation || handle_error "Failed to execute maridb-secure-installation"

read -p "Enter database name (default 'semaphore_db'): " DB_NAME
DB_NAME=${DB_NAME:-semaphore_db}
echo -e "\e[32mDatabase Name: $DB_NAME\e[0m"

read -p "Enter database user (default 'semaphore_user'): " DB_USER
DB_USER=${DB_USER:-semaphore_user}
echo -e "\e[32mDatabase User: $DB_USER\e[0m"

while true; do
    read -s -p "Enter password for user '$DB_USER': " DB_PASS
    echo
    read -s -p "Confirm password: " DB_PASS_CONFIRM
    echo
    if [[ "$DB_PASS" != "$DB_PASS_CONFIRM" ]]; then
        echo -e "\e[31mPasswords do not match. Please try again.\e[0m"
    elif [[ -z "$DB_PASS" ]]; then
        echo -e "\e[31mPassword cannot be empty.\e[0m"
    else
        break
    fi
done
echo -e "\e[32mPassword confirmed.\e[0m"

echo -e "\e[34mCreating MariaDB database and user...\e[0m"

sudo mariadb <<EOF
CREATE DATABASE $DB_NAME;
GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@localhost IDENTIFIED BY '$DB_PASS';
FLUSH PRIVILEGES;
EOF

echo -e "\e[32mDatabase $DB_NAME and user $DB_USER created successfully.\e[0m"

check_or_install_app "semaphore setup" "semaphore" "wget https://github.com/semaphoreui/semaphore/releases/download/v2.12.4/semaphore_2.12.4_linux_amd64.deb"
sudo sudo dpkg -i semaphore_2.12.4_linux_amd64.deb || handle_error "Failed to unpack semaphore_2.12.4_linux_amd64.deb"

echo -e "\e[34mSetting up semaphore environment...\e[0m"
semaphore setup
sudo mkdir /etc/semaphore || handle_error "Failed to create /etc/semaphore"
sudo mv config.json /etc/semaphore/config.json || handle_error "Failed to move config.json to /etc/semaphore"

echo -e "\e[34mCreating semaphore service...\e[0m"
sudo wget https://raw.githubusercontent.com/KevinRexFromDk/ansible/refs/heads/main/semaphore.service -O /etc/systemd/system/semaphore.service || handle_error "Unable to retrieve semaphore.service - check your network connection"
sudo systemctl start semaphore
sudo systemctl enable semaphore

sudo apt install sshpass -y
sudo apt install ansible -y

sudo rm -f $(pwd)/semaphore_2.12.4_linux_amd64.deb
