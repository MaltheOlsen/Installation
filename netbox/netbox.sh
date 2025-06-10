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
SECRET_KEY=$(python3 ../generate_secret_key.py)
sudo sed -i "s/^SECRET_KEY = ['\"].*['\"]$/SECRET_KEY = '${SECRET_KEY}'/" /opt/netbox/netbox/netbox/configuration.py

# Run the Upgrade Script #
echo -e "\e[34mRunning the upgrade script\e[0m"
sudo /opt/netbox/upgrade.sh

# Create a Super User #
echo -e "\e[34mCreating Super User\e[0m"
source /opt/netbox/venv/bin/activate
cd /opt/netbox/netbox


SUPERUSER_USERNAME="admin"
SUPERUSER_EMAIL="admin@example.com"
SUPERUSER_PASSWORD=$(openssl rand -base64 12) # Generates a 12-char random base64 string for password

# You could also use a hardcoded password for testing (not recommended for production):
# SUPERUSER_PASSWORD="YourSecurePassword123"

# --- Script Logic ---

echo "Creating Django superuser..."

# Set environment variables for the createsuperuser command
DJANGO_SUPERUSER_USERNAME=$SUPERUSER_USERNAME \
DJANGO_SUPERUSER_EMAIL=$SUPERUSER_EMAIL \
DJANGO_SUPERUSER_PASSWORD=$SUPERUSER_PASSWORD \
python3 manage.py createsuperuser --noinput

if [ $? -eq 0 ]; then
    echo "Superuser '$SUPERUSER_USERNAME' created successfully."
    echo "Username: $SUPERUSER_USERNAME"
    echo "Email: $SUPERUSER_EMAIL"
    echo "Password: $SUPERUSER_PASSWORD" # Be careful with logging passwords in production
else
    echo "Error: Superuser creation failed."
    # If the user already exists, createsuperuser --noinput will exit with 0.
    # You might want to add logic to check if the user already exists before attempting to create.
    # Example: python manage.py shell -c "from django.contrib.auth import get_user_model; User=get_user_model(); print(User.objects.filter(username='admin').exists())"
fi

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
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/private/netbox.key \
-out /etc/ssl/certs/netbox.crt

## HTTP Server Installation NGINX ##
echo -e "\e[34mNGINX Installation\e[0m"
sudo apt install -y nginx
sudo cp /opt/netbox/contrib/nginx.conf /etc/nginx/sites-available/netbox
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/netbox /etc/nginx/sites-enabled/netbox
sudo systemctl restart nginx
