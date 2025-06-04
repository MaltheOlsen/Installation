#!/bin/bash

cd uptime-kuma

# Update from git
git fetch --all
git checkout 1.23.16 --force

# Install dependencies and prebuilt
npm install --production
npm run download-dist

# Restart
pm2 restart uptime-kuma
