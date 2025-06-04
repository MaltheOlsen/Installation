# 🚀 Semaphore Auto Install Script

This repository contains an automated installation scripts for setting up **Semaphore UI** with **MariaDB** on an Ubuntu server 24.04.

## 🔧 Features

- Automates the installation of **Semaphore** 🐱‍💻
- Installs and configures **MariaDB** for Semaphore 🛠️
- Prompts for **MariaDB** and **Semaphore** settings (with default values) 📝
- Handles installation failures and exits gracefully 🚨

## 📥 Fetch the Install Script

To fetch the latest version of the `semaphorePM-autoinstall.sh` script, run the following command:

```bash
wget https://raw.githubusercontent.com/KevinRexFromDk/ansible/refs/heads/main/semaphorePM-autoinstall.sh -O semaphorePM-autoinstall.sh
```

# ⚙️ Change Execute Permissions
Once the script is downloaded, you'll need to make it executable. Use the following command to change the script's permissions:

```bash
sudo chmod +x semaphorePM-autoinstall.sh
```

# 🚀 Running the Script
After making the script executable, you can run it using the following command:

```bash
sudo ./semaphorePM-autoinstall.sh
```

# 🛠️ Script Behavior
 - The script will automatically handle the installation of all required dependencies (Semaphore, MariaDB). 🏗️
 - If any step fails, the script will stop and print an error message. ⚠️
 - After a successful installation, a "completed successfully" message will appear in green. 🎉
