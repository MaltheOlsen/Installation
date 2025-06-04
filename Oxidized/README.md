# 🚀 Semaphore Auto Install Script

This repository contains an automated installation scripts for setting up **Oxidized** on an Ubuntu server 24.04.

## 🔧 Features

- Automates the installation of **Oxidized** 🐱‍💻
- Prompts for **Oxidized** settings 📝

## 📥 Fetch the Install Script

To fetch the latest version of the `Oxidized-AutoInstall.sh` script, run the following command:

```bash
wget https://raw.githubusercontent.com/MaltheOlsen/Installation/refs/heads/main/Oxidized/Oxidized-AutoInstall.sh?token=GHSAT0AAAAAADED733VNLPSEUC2YJCZZUKQ2CADGTQ -O Oxidized-AutoInstall.sh
```

# ⚙️ Change Execute Permissions
Once the script is downloaded, you'll need to make it executable. Use the following command to change the script's permissions:

```bash
sudo chmod +x Oxidized-AutoInstall.sh
```

# 🚀 Running the Script
- After making the script executable, you can run it using the following command:

```bash
sudo ./Oxidized-AutoInstall.sh
```

# ⚙️ Add devices to your Oxi and configure a SSL cert
Configure /etc/oxidized/devices.db, and proper SSL certificate

# 🛠️ Script Behavior
 - The script will automatically handle the installation of all required dependencies. 🏗️
 - If any step fails, the script will stop and print an error message. ⚠️
 - After a successful installation, a "completed successfully" message will appear in green. 🎉

# Tyvstjålet fra Kevin T-Rex
