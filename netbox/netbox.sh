## NETBOX ##
sudo apt update && sudo apt upgrade -y

# Install System Packages
sudo apt install -y python3 python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev zlib1g-dev

# Download a Release Archive
mkdir /opt/netbox-4.2.8
sudo wget https://github.com/netbox-community/netbox/archive/refs/tags/v4.2.8.tar.gz
sudo tar -xzf v4.2.8.tar.gz -C /opt
sudo ln -s /opt/netbox-4.2.8/ /opt/netbox

# Create the NetBox System User
sudo adduser --system --group netbox
sudo chown --recursive netbox /opt/netbox/netbox/media/
sudo chown --recursive netbox /opt/netbox/netbox/reports/
sudo chown --recursive netbox /opt/netbox/netbox/scripts/

# Configuration
cd /opt/netbox/netbox/netbox/
sudo cp configuration_example.py configuration.py

## Edit the following lines in configuration.py
#    ALLOWED_HOSTS - ALLOWED_HOSTS = ['netbox.example.com', '192.0.2.123']
#    DATABASE - PostgreSQL oplysninger
#    REDIS - Tasks and Caching database need a unique ID, eks. 0 for tasks and 1 for caching
#    SECRET_KEY - Generate a key by executing - python3 ../generate_secret_key.py

# Create a Super User/Web User
source /opt/netbox/venv/bin/activate

cd /opt/netbox/netbox
python3 manage.py createsuperuser

# Schedule the Housekeeping Task
#NetBox includes a housekeeping management command that handles some recurring cleanup tasks, such as clearing out old sessions and expired change records.
sudo ln -s /opt/netbox/contrib/netbox-housekeeping.sh /etc/cron.daily/netbox-housekeeping
