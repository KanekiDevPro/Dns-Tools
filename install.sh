#!/bin/bash

REPO="https://github.com/KanekiDevPro/dns-tool.sh"
DIR="dns-tool.sh"

if [ -d "$DIR" ]; then
  echo "Directory $DIR exists. Pulling latest changes..."
  cd "$DIR" && git pull origin main
else
  echo "Cloning repository..."
  git clone "$REPO"
  cd "$DIR"
fi

chmod +x dns-tool.sh
sudo ./dns-tool.sh
