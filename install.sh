#!/bin/bash

REPO="https://github.com/KanekiDevPro/dns-tool.sh"
DIR="dns-tool"

# چک کن فولدر هست یا نه
if [ -d "$DIR" ]; then
  echo "[*] Directory $DIR exists. Pulling latest changes..."
  cd "$DIR" || { echo "Failed to cd into $DIR"; exit 1; }
  git pull origin main || { echo "Failed to pull latest changes"; exit 1; }
else
  echo "[*] Cloning repository..."
  git clone "$REPO" || { echo "Failed to clone repo"; exit 1; }
  cd "$DIR" || { echo "Failed to cd into $DIR"; exit 1; }
fi

# اجازه اجرا به اسکریپت بده
chmod +x dns-tool.sh

echo "[*] Running dns-tool.sh script with sudo..."
sudo ./dns-tool.sh
