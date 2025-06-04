# 🥑 Guacamole Auto Install Script

This repository contains an automated installation script for setting up **Guacamole** with **Tomcat**, **MySQL**, and **Guacamole Server** on an Ubuntu server 24.04.

## 🔧 Features

- Automates the installation of **Tomcat 9** 🐱‍💻
- Installs and configures **MySQL** for Guacamole 🛠️
- Configures **Guacamole server** with Tomcat 🖥️
- Prompts for **MySQL** and **Guacamole** settings (with default values) 📝
- Handles installation failures and exits gracefully 🚨

## 📥 Fetch the Install Script

To fetch the latest version of the `guac-autoinstall.sh` script, run the following command:

```bash
wget https://raw.githubusercontent.com/KevinRexFromDk/guacamole/refs/heads/main/guac-autoinstall.sh -O guac-autoinstall.sh
```

# ⚙️ Change Execute Permissions
Once the script is downloaded, you'll need to make it executable. Use the following command to change the script's permissions:

```bash
sudo chmod +x guac-autoinstall.sh
```

# 🚀 Running the Script
After making the script executable, you can run it using the following command:

```bash
sudo ./guac-autoinstall.sh
```

The script will prompt you to enter the following details during the installation process:
 - MySQL Password (default: Passw0rd) 🔑
 - Guacamole Password (default: Passw0rd) 🔒
 - Guacamole Database Name (default: guac_db) 🗄️
 - Guacamole Username (default: guacadmin) 👤

If you leave the inputs blank, the default values will be used.

# 🛠️ Script Behavior
 - The script will automatically handle the installation of all required dependencies (Tomcat, MySQL, Guacamole). 🏗️
 - If any step fails, the script will stop and print an error message. ⚠️
 - After a successful installation, a "completed successfully" message will appear in green. 🎉

# 🔧 Customization
You can modify the default values for the following parameters by simply entering them when prompted:
 - MySQL Password 💬
 - Guacamole Password 🔐
 - Guacamole Database Name 🗃️
 - Guacamole Username 👤

If you leave the input blank, default values will be used. 📜

# Example of Input Prompt
```bash
Kopiér
Rediger
Enter MySQL password (default 'Passw0rd'): Passw0rd
Enter Guacamole password (default 'Passw0rd'): Passw0rd
Enter Guacamole database name (default 'guac_db'): guac_db
Enter Guacamole username (default 'guacadmin'): guacadmin
```
