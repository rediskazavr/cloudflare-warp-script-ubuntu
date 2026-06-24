#!/bin/bash
os=$(lsb_release -is)

if [[ "$os" == "Ubuntu" ]] || [[ $os == "Debian" ]]; then
    true
else
        echo "Aborted. Script only use for Ubuntu/Debian"
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
read number

if [[ "$number" == 1 ]]; then
    echo "Installing cloudflare warp"
    curl -fsSL https://cloudflareclient.com | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://cloudflareclient.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-warp.list
    sudo apt update && sudo apt install cloudflare-warp -y
    warp-cli registration new
    echo Y
    warp-cli mode proxy
    warp-cli connect
    curl https://www.cloudflare.com/cdn-cgi/trace | grep warp=on
elif [[ $number == 2 ]]; then
    echo "Deleting cloudflare warp"
    warp-cli disconnect
    warp-cli delete
    sudo apt remove --purge cloudflare-warp -y
    sudo apt autoremove -y
    rm -rf ~/.cloudflare
    sudo systemctl restart systemd-resolved
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
elif [[ $number == 3 ]]; then
    echo "Goodbye!"
    exit 1
else
    echo "Aborted."
    exit 1
fi