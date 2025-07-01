#!/bin/bash
# bootstrap.sh - Download and run DNS Setup & Test Tool from GitHub

REPO_RAW_URL="https://raw.githubusercontent.com/KanekiDevPro/Dns-Tools/main/dns-tool.sh"
LOCAL_SCRIPT="/usr/local/bin/dns-tool.sh"

# چک کردن نصب بودن curl، نصبش کن اگر نیست
if ! command -v curl &>/dev/null; then
    echo "curl is not installed. Installing..."
    apt update -y && apt install -y curl
fi

echo "Downloading DNS tool script..."
curl -fsSL "$REPO_RAW_URL" -o "$LOCAL_SCRIPT"
if [[ $? -ne 0 ]]; then
    echo "Failed to download the script from $REPO_RAW_URL"
    exit 1
fi

chmod +x "$LOCAL_SCRIPT"

echo "Running DNS tool..."
sudo bash "$LOCAL_SCRIPT"
