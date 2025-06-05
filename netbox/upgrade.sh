NEWVER=4.3.2
OLDVER=4.3.1
# Set $NEWVER to the NetBox version being installed
wget https://github.com/netbox-community/netbox/archive/v$NEWVER.tar.gz
sudo tar -xzf v$NEWVER.tar.gz -C /opt
sudo ln -sfn /opt/netbox-$NEWVER/ /opt/netbox

# Set $OLDVER to the NetBox version currently installed
sudo cp /opt/netbox-$OLDVER/local_requirements.txt /opt/netbox/
sudo cp /opt/netbox-$OLDVER/netbox/netbox/configuration.py /opt/netbox/netbox/netbox/
sudo cp /opt/netbox-$OLDVER/netbox/netbox/ldap_config.py /opt/netbox/netbox/netbox/

sudo cp -pr /opt/netbox-$OLDVER/netbox/media/ /opt/netbox/netbox/
sudo cp -r /opt/netbox-$OLDVER/netbox/scripts /opt/netbox/netbox/
sudo cp -r /opt/netbox-$OLDVER/netbox/reports /opt/netbox/netbox/
sudo cp /opt/netbox-$OLDVER/gunicorn.py /opt/netbox/

sudo ./upgrade.sh
sudo systemctl restart netbox netbox-rq
