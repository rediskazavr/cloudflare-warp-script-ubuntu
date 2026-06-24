#!/bin/bash

# Проверяем ОС через /etc/os-release (надежнее, чем lsb_release)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        echo "Aborted. Script only for Ubuntu/Debian"
        exit 1
    fi
else
    echo "Cannot determine OS. Aborted."
    exit 1
fi

echo '================================================='
echo 'CLOUDFLARE WARP INSTALLER [by github/rediskazavr]'
echo '================================================='

echo "What do you want?"
echo "[1] - Install WARP"
echo "[2] - Delete WARP"
echo "[3] - Exit"
echo -n "Enter number: "
read -r number

VERSION_CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)

if [[ "$number" == "1" ]]; then
    echo "Installing cloudflare warp..."
    
    sudo apt update && sudo apt install curl gnupg lsb-release -y
    
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $VERSION_CODENAME main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
    
    sudo apt update && sudo apt install cloudflare-warp -y
    
    echo "Registering WARP client..."
    warp-cli --accept-tos registration new
    
    warp-cli mode proxy
    warp-cli connect
    
    sleep 3
    
    echo "Checking connection..."
    if curl --socks5-hostname 127.0.0.1:4000 -s https://www.cloudflare.com/cdn-cgi/trace | grep -q "warp=on"; then
        echo "Success! WARP is active on 127.0.0.1:4000"
    else
        echo "Warning: WARP installed, but proxy check failed."
    fi

elif [[ "$number" == "2" ]]; then
    echo "Deleting cloudflare warp..."
    warp-cli disconnect 2>/dev/null
    warp-cli delete 2>/dev/null
    sudo apt remove --purge cloudflare-warp -y
    sudo apt autoremove -y
    rm -rf ~/.cloudflare
    rm -f /etc/apt/sources.list.d/cloudflare-client.list
    
    sudo systemctl restart systemd-resolved
    
    echo "WARP successfully removed."

elif [[ "$number" == "3" ]]; then
    echo "Goodbye!"
    exit 0
else
    echo "Aborted. Invalid option."
    exit 1
fi