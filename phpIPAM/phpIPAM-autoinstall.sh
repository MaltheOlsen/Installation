#!/bin/bash

handle_error() {
    echo -e "\e[31mError: $1\e[0m"
    exit 1
}
echo -e "\e[34mUpdating and upgrading the system...\e[0m"
sudo apt-get update -y && sudo apt-get upgrade -y || handle_error "System update/upgrade failed."

echo -e "\e[34mChecking prerequisites (curl, wget, zip, git, apache2, mariadb-server, mariadb-client, and php modules)...\e[0m"
sudo apt install curl wget zip git apache2 mariadb-server mariadb-client php php-curl php-common php-gmp php-mbstring php-gd php-xml php-mysql php-ldap php-pear -y || handle_error "Failed to install prerequisites"
sudo mysql_secure_installation || handle_error "Failed to execute mysql_secure_installation, are you root?"

read -p "Enter database name (default 'phpipam'): " DB_NAME
DB_NAME=${DB_NAME:-phpipam}
echo -e "\e[32mDatabase Name: $DB_NAME\e[0m"

read -p "Enter database user (default 'phpipamadmin'): " DB_USER
DB_USER=${DB_USER:-phpipamadmin}
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

echo -e "\e[34mCreating MySQL database and user...\e[0m"

mysql -u root -p<<EOF
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

echo -e "\e[32mDatabase $DB_NAME and user $DB_USER created successfully.\e[0m"

echo -e "\e[34mCloning phpIPAM git...\e[0m"
sudo git clone https://github.com/phpipam/phpipam.git /var/www/html/phpipam

echo -e "\e[34mOrganizing phpIPAM config...\e[0m"
sudo chown -R www-data:www-data /var/www/html/phpipam || handle_error "Failed to change ownership on dir: /var/www/html/phpipam"
sudo cp /var/www/html/phpipam/config.dist.php /var/www/html/phpipam/config.php || handle_error "Failed to copy and rename: /var/www/html/phpipam/config.dist.php >> /var/www/html/phpipam/config.php"
sed -i \
  -e "s/^\(\$db\['user'\] = \).*/\1'${DB_USER}';/" \
  -e "s/^\(\$db\['pass'\] = \).*/\1'${DB_PASS}';/" \
  -e "s/^\(\$db\['name'\] = \).*/\1'${DB_NAME}';/" \
#  -e "/^\$db\['port'\] = 3306;/a define('BASE', \"/phpipam/\");" \
  /var/www/html/phpipam/config.php || handle_error "Failed to organize and modify file: /var/www/html/phpipam/config.php"


echo -e "\e[34mEnabling apache2 mod_rewrite\e[0m"
sudo a2enmod rewrite || handle_error "Failed to enable apache2 mod_rewrite"
echo -e "\e[32mSuccess\e[0m"

echo -e "\e[34mRestarting Apache2...\e[0m"
sudo systemctl restart apache2 || handle_error "Unable to restart service: apache2.service"
echo -e "\e[32mphpIPAM install done\e[0m"

echo -e "\e[32mUse the following to finish phpIPAM configuration:
 1. Go to http://$(hostname -I | awk '{print $1}')/phpipam
 2. Click 'New phpipam installation' button
 3. Click 'Automatic database installation'
 4. Insert the following information:
     MYSQL Username: $DB_USER
     MYSQL Password: [Hidden]
     MYSQL Location: 127.0.0.1
     MYSQL DB name: $DB_NAME
 5. Click 'Show advanced options' button
  5.1 Uncheck 'Create new database' and 'Set permissions to tables'
  5.2 Click the 'Install phpipam database' button
 6. Click 'Proceed to login' and login with username 'admin' and associated password you set earlier
\e[0m"
