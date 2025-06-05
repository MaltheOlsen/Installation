#!/bin/bash

handle_error() {
    echo -e "\e[31mError: $1\e[0m"
    exit 1 
}

echo -e "\e[34mUpdating and upgrading the system...\e[0m"
sudo apt-get update -y && sudo apt-get upgrade -y || handle_error "System update/upgrade failed."

echo -e "\e[34mInstalling OpenJDK 11...\e[0m"
sudo apt-get install openjdk-11-jdk -y || handle_error "OpenJDK 11 installation failed."

echo -e "\e[34mDownloading Tomcat 9...\e[0m"
wget -q https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.102/bin/apache-tomcat-9.0.102.tar.gz || handle_error "Tomcat download failed."

echo -e "\e[34mInstalling Tomcat 9...\e[0m"
sudo mkdir /etc/tomcat9 || handle_error "Failed to create Tomcat directory."
sudo tar -xvzf apache-tomcat-9.0.102.tar.gz -C /etc/tomcat9 || handle_error "Failed to extract Tomcat files."
sudo mv /etc/tomcat9/apache-tomcat-9.0.102/* /etc/tomcat9 || handle_error "Failed to move Tomcat files."
sudo rm -rf /etc/tomcat9/apache-tomcat-9.0.102 || handle_error "Failed to remove extracted files."
sudo rm -f apache-tomcat-9.0.102.tar.gz || handle_error "Failed to remove Tomcat tar file."

echo -e "\e[34mDownloading systemd service file for Tomcat9...\e[0m"
wget -q https://raw.githubusercontent.com/MaltheOlsen/Installation/refs/heads/main/Guacamole-RemoteTool/tomcat9.service -O /etc/systemd/system/tomcat9.service || handle_error "Failed to download tomcat9.service file."

echo -e "\e[34mStarting and enabling Tomcat9 service...\e[0m"
sudo systemctl start tomcat9 || handle_error "Failed to start Tomcat service."
sudo systemctl enable tomcat9 || handle_error "Failed to enable Tomcat service."

echo -e "\e[34mDownloading Guacamole installation script...\e[0m"
wget -q https://git.io/fxZq5 -O guac-install.sh || handle_error "Guacamole installation script download failed."
chmod +x guac-install.sh || handle_error "Failed to make Guacamole script executable."

echo -e "\e[34mModifying Guacamole installation script...\e[0m"
sed -i '/if \[\[ $( apt-cache show tomcat9 /,/^fi$/d' guac-install.sh || handle_error "Failed to modify Guacamole installation script."
sed -i 's/^#TOMCAT=""/TOMCAT=tomcat9/' guac-install.sh || handle_error "Failed to set TOMCAT variable in script."
sed -i '/${MYSQL} ${LIBJAVA} ${TOMCAT} &>> ${LOG}/c\${MYSQL} ${LIBJAVA} &>> ${LOG}' guac-install.sh || handle_error "Failed to modify MySQL, LIBJAVA, TOMCAT logging in script."
sed -i 's|ln -sf /etc/guacamole/guacamole.war /var/lib/${TOMCAT}/webapps/|ln -sf /etc/guacamole/guacamole.war /etc/${TOMCAT}/webapps/|' guac-install.sh || handle_error "Failed to update the ln command in script."

echo -e "\e[34mRunning Guacamole installation script...\e[0m"
sudo ./guac-install.sh
echo -e "\e[32mInstallation completed successfully!\e[0m"

echo -e "\e[34mCleaning up...\e[0m"
sudo rm -f apache-tomcat-9.0.102.*
sudo rm -f guac-install.sh
sudo rm -f guac-autoinstall.sh
echo -e "\e[32mCleanup completed successfully!\e[0m"
