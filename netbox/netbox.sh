#!/bin/bash

## NETBOX ##
sudo apt update && sudo apt upgrade -y

## PostgreSQL Database Installation ##
sudo apt update
sudo apt install -y postgresql

## Database Creation ##
sudo -u postgres psql

CREATE DATABASE netbox;
CREATE USER netbox WITH PASSWORD 'Passw0rd';
ALTER DATABASE netbox OWNER TO netbox;
\connect netbox;
GRANT CREATE ON SCHEMA public TO netbox;
\q

# Test database
# psql --username netbox --password --host localhost netbox

## Redis Installation ##
sudo apt install -y redis-server
# Test Redis #
# verify that your installed version of Redis is at least v4.0 - redis-server -v
# If successful, you should receive a PONG response from the server. - redis-cli ping

## NetBox Installation ##
sudo apt install -y python3 python3-pip python3-venv python3-dev \
build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev \
libssl-dev zlib1g-dev

sudo wget https://github.com/netbox-community/netbox/archive/refs/tags/v4.3.1.tar.gz
sudo tar -xzf v4.3.1.tar.gz -C /opt
sudo ln -s /opt/netbox-4.3.1/ /opt/netbox

# Create the NetBox System User #
sudo adduser --system --group netbox
sudo chown --recursive netbox /opt/netbox/netbox/media/
sudo chown --recursive netbox /opt/netbox/netbox/reports/
sudo chown --recursive netbox /opt/netbox/netbox/scripts/

# netbox Configuration #
cd /opt/netbox/netbox/netbox/
sudo cp configuration_example.py configuration.py

# ALLOWED_HOSTS #
sed -i 's/^ALLOWED_HOSTS*/ALLOWED_HOSTS = ['*']/' /opt/netbox/netbox/netbox/configuration.py

# DATABASES #
sed -i "/^DATABASES = {/,/^}$/c\\
DATABASES = {\\
    'default': {\\
        'NAME': 'netbox',\\
        'USER': 'netbox',\\
        'PASSWORD': 'DIT_NYE_PASSWORD',\\
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
python3 ../generate_secret_key.py

# Run the Upgrade Script #
deactivate

sudo /opt/netbox/upgrade.sh
sudo PYTHON=/usr/bin/python3.10 /opt/netbox/upgrade.sh

# Create a Super User #
source /opt/netbox/venv/bin/activate
cd /opt/netbox/netbox
python3 manage.py createsuperuser
---------------------------------------------------------------------------------------------------------------------------------------------------------
# Housekeeping Task #
sudo ln -s /opt/netbox/contrib/netbox-housekeeping.sh /etc/cron.daily/netbox-housekeeping

# Test the Application #
# python3 manage.py runserver 0.0.0.0:8000 --insecure

## Gunicorn ##
# Configuration #
sudo cp /opt/netbox/contrib/gunicorn.py /opt/netbox/gunicorn.py

# systemd Setup #
sudo cp -v /opt/netbox/contrib/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now netbox netbox-rq
# verify it is running - systemctl status netbox.service

## Obtain an SSL Certificate ##
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/private/netbox.key \
-out /etc/ssl/certs/netbox.crt

## HTTP Server Installation NGINX ##
sudo apt install -y nginx
sudo cp /opt/netbox/contrib/nginx.conf /etc/nginx/sites-available/netbox
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/netbox /etc/nginx/sites-enabled/netbox
sudo systemctl restart nginx
