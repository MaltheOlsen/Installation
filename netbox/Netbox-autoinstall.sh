#!/bin/bash

## NETBOX ##
echo -e "\e[34mUpdating and upgrading the system...\e[0m"
sudo apt update && sudo apt upgrade -y

## PostgreSQL Database Installation ##
echo -e "\e[34mPostgreSQL Database Installation\e[0m"
sudo apt update
sudo apt install -y postgresql

## Database Creation ##
echo -e "\e[34mDatabase Creation\e[0m"
sudo -u postgres psql<<EOF
CREATE DATABASE netbox;
CREATE USER netbox WITH PASSWORD 'Passw0rd';
ALTER DATABASE netbox OWNER TO netbox;
\connect netbox;
GRANT CREATE ON SCHEMA public TO netbox;
\q
EOF

# Test database
# psql --username netbox --password --host localhost netbox

## Redis Installation ##
echo -e "\e[34mRedis\e[0m"
sudo apt install -y redis-server
# Test Redis #
# verify that your installed version of Redis is at least v4.0 - redis-server -v
# If successful, you should receive a PONG response from the server. - redis-cli ping

## NetBox Installation ##
echo -e "\e[34mNetbox Installation\e[0m"
sudo apt install -y python3 python3-pip python3-venv python3-dev \
build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev \
libssl-dev zlib1g-dev

sudo wget https://github.com/netbox-community/netbox/archive/refs/tags/v4.3.1.tar.gz
sudo tar -xzf v4.3.1.tar.gz -C /opt
sudo ln -s /opt/netbox-4.3.1/ /opt/netbox

# Create the NetBox System User #
echo -e "\e[34mCreating NetBox User\e[0m"
sudo adduser --system --group netbox
sudo chown --recursive netbox /opt/netbox/netbox/media/
sudo chown --recursive netbox /opt/netbox/netbox/reports/
sudo chown --recursive netbox /opt/netbox/netbox/scripts/

# netbox Configuration #
echo -e "\e[34mNetBox Configuration\e[0m"
cd /opt/netbox/netbox/netbox/
sudo cp configuration_example.py configuration.py

# ALLOWED_HOSTS #
NETBOX_CONFIG_FILE="/opt/netbox/netbox/netbox/configuration.py"
sudo sed -i "s/^ALLOWED_HOSTS = .*$/ALLOWED_HOSTS = ['*']/" "$NETBOX_CONFIG_FILE"

# DATABASES #
sed -i "/^DATABASES = {/,/^}$/c\\
DATABASES = {\\
    'default': {\\
        'NAME': 'netbox',\\
        'USER': 'netbox',\\
        'PASSWORD': 'Passw0rd',\\
        'HOST': 'localhost',\\
        'PORT': '',\\
        'CONN_MAX_AGE': 300,\\
    }\\
}" /opt/netbox/netbox/netbox/configuration.py

# REDIS #
sed -i '/^REDIS = {/,/^}$/c\
REDIS = {\
    '\''tasks'\'': {\
        '\''HOST'\'': '\''localhost'\'',\
        '\''PORT'\'': 6379,\
        '\''PASSWORD'\'': '\'''\'',\
        '\''DATABASE'\'': 0,\
        '\''SSL'\'': False,\
    },\
    '\''caching'\'': {\
        '\''HOST'\'': '\''localhost'\'',\
        '\''PORT'\'': 6379,\
        '\''PASSWORD'\'': '\'''\'',\
        '\''DATABASE'\'': 1,\
        '\''SSL'\'': False,\
    }\
}' /opt/netbox/netbox/netbox/configuration.py

# SECRET_KEY #
SECRET_KEY=$(python3 ../generate_secret_key.py)
sudo sed -i "s/^SECRET_KEY = ['\"].*['\"]$/SECRET_KEY = '${SECRET_KEY}'/" /opt/netbox/netbox/netbox/configuration.py

# Run the Upgrade Script #
echo -e "\e[34mRunning the upgrade script\e[0m"
sudo /opt/netbox/upgrade.sh

# Create a Super User #
echo -e "\e[34mCreating Super User\e[0m"
source /opt/netbox/venv/bin/activate
cd /opt/netbox/netbox



read -p "SuperUser Username (default 'admin'): " SUPERUSER_USERNAME
SUPERUSER_USERNAME=${SUPERUSER_USERNAME:-admin}
echo -e "\e[32mSuperUser Username: $SUPERUSER_USERNAME\e[0m"

read -p "SuperUser Email (default 'admin@example.com'): " SUPERUSER_EMAIL
SUPERUSER_EMAIL=${SUPERUSER_EMAIL:-admin@example.com}
echo -e "\e[32mSuperUser Email: $SUPERUSER_EMAIL\e[0m"

read -p "SuperUser Password: " SUPERUSER_PASSWORD
echo -e "\e[32mSuperUser Password: $SUPERUSER_PASSWORD\e[0m"

echo "Creating Django superuser..."

# Set environment variables for the createsuperuser command
DJANGO_SUPERUSER_USERNAME=$SUPERUSER_USERNAME \
DJANGO_SUPERUSER_EMAIL=$SUPERUSER_EMAIL \
DJANGO_SUPERUSER_PASSWORD=$SUPERUSER_PASSWORD \
python3 manage.py createsuperuser --noinput

# Housekeeping Task #
sudo ln -s /opt/netbox/contrib/netbox-housekeeping.sh /etc/cron.daily/netbox-housekeeping

# Test the Application #
# python3 manage.py runserver 0.0.0.0:8000 --insecure

## Gunicorn ##
echo -e "\e[34mConfigure Gunicorn\e[0m"
# Configuration #
sudo cp /opt/netbox/contrib/gunicorn.py /opt/netbox/gunicorn.py

# systemd Setup #
sudo cp -v /opt/netbox/contrib/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now netbox netbox-rq
# verify it is running - systemctl status netbox.service

## Obtain an SSL Certificate ##
echo -e "\e[34mSSL Certificate\e[0m"

# Define certificate paths
KEY_PATH="/etc/ssl/private/netbox.key"
CRT_PATH="/etc/ssl/certs/netbox.crt"

SUBJECT_DN="/C=/ST=/L=/O=/OU=/CN=netbox.local/emailAddress="
echo "Generating self-signed SSL certificate and key..."

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout "$KEY_PATH" \
-out "$CRT_PATH" \
-subj "$SUBJECT_DN" # Use the -subj option to specify all details

sudo chmod 644 "$CRT_PATH"

echo "Self-signed certificate and key generated successfully:"
echo "Key: $KEY_PATH"
echo "Cert: $CRT_PATH"


## HTTP Server Installation NGINX ##
echo -e "\e[34mNGINX Installation\e[0m"
sudo apt install -y nginx
sudo cp /opt/netbox/contrib/nginx.conf /etc/nginx/sites-available/netbox
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/netbox /etc/nginx/sites-enabled/netbox
sudo systemctl restart nginx
