#!/bin/bash

CONFIG_PATH="/etc/oxidized/config"
HOSTNAME=hostname

add-apt-repository universe
apt install ruby ruby-dev libsqlite3-dev libssl-dev pkg-config cmake libssh2-1-dev libicu-dev zlib1g-dev g++ libyaml-dev apache2

gem install oxidized
gem install oxidized-web
gem install oxidized-script

mkdir /etc/oxidized

echo "Enter your Oxidized username:"
read -r USERNAME

echo "Enter your Oxidized password:"
read -rs PASSWORD
echo

echo "Enter your Oxidized enable password:"
read -rs ENABLE_PASSWORD
echo

echo "Enter the FQDN or IP of this device:"
read -rs FQDN
echo

cat > "$CONFIG_PATH" <<EOF
---
username: $USERNAME
password: $PASSWORD
model: ios
resolve_dns: true
interval: 3600
use_syslog: false
debug: false
run_once: false
threads: 30
use_max_threads: false
timeout: 20
retries: 3
prompt: !ruby/regexp /^([\w.@-]+[#>]\s?)$/
next_adds_job: false
vars: {}
groups: {}
group_map: {}
models: {}
pid: "/etc/oxidized/pid"
extensions:
  oxidized-web:
    load: true
crash:
  directory: "/etc/oxidized/crashes"
  hostnames: false
stats:
  history_size: 10
input:
  default: ssh
  debug: false
  ssh:
    secure: false
  ftp:
    passive: true
  utf8_encoded: true
output:
  default: git
  file:
    user: Oxidized
    email: Oxidized@localhost
    directory: "/etc/oxidized/backup.git"
source:
  default: csv
  csv:
    file: "/etc/oxidized/devices.db"
    delimiter: !ruby/regexp /:/
    map:
      name: 0
vars:
  enable: $ENABLE_PASSWORD

EOF

echo "Oxidized configuration written to $CONFIG_PATH"

cat > "/etc/oxidized/devices.db" <<EOF
router1:cisco:192.168.1.1
router2:cisco:192.168.1.2
EOF
echo "Oxidized devices written to /etc/oxidized/devices.db"

cd /etc/oxidized
git init backup.git
cd backup.git
git config user.name "Oxidized"
git config user.email "oxidized@localhost"

mkdir /etc/oxidized/crashes
mkdir /etc/oxidized/pid


cat > "/etc/systemd/system/oxidized.service" <<EOF
[Unit]
Description=Oxidized Network Configuration Backup Service
After=network.target

[Service]
Environment=OXIDIZED_HOME=/etc/oxidized
ExecStart=/usr/local/bin/oxidized
User=administrator
WorkingDirectory=/etc/oxidized
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable oxidized

a2enmod proxy
a2enmod proxy_http
a2enmod ssl
a2enmod rewrite

rm /etc/apache2/sites-enabled/000-default.conf
mkdir /etc/apache2/ssl

cat > "/etc/apache2/sites-available/oxidized.conf" <<EOF
<VirtualHost *:80>
    ServerName $HOSTNAME
    Redirect permanent / https://$FQDN/
</VirtualHost>

<VirtualHost *:443>
    ServerName $HOSTNAME

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/oxidized.crt
    SSLCertificateKeyFile /etc/apache2/ssl/oxidized.key

    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8888/
    ProxyPassReverse / http://127.0.0.1:8888/

    ErrorLog ${APACHE_LOG_DIR}/oxidized-error.log
    CustomLog ${APACHE_LOG_DIR}/oxidized-access.log combined
</VirtualHost>
EOF

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/apache2/ssl/oxidized.key \
  -out /etc/apache2/ssl/oxidized.crt

a2ensite oxidized.conf
systemctl restart apache2
