#!/bin/bash

# COLORS
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
LIGHT_YELLOW="\e[93m"
ENDCOLOR="\e[0m"

reset_colors() {
	echo -ne "\e[0m"
}

trap reset_colors EXIT INT

echo -ne "\e[38;2;255;140;0m"

clear

if [ -f /etc/os-release ]; then
	. /etc/os-release
	if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
		echo -e "${RED}Aborted. Script only use for Ubuntu/Debian ${ENDCOLOR}"
		exit 1
	fi
else
	echo -e "${RED}Cannot determined distro. Aborted ${ENDCOLOR}"
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
	echo -e "${GREEN}Installing WARP... ${ENDCOLOR}"

	sudo rm -f /etc/apt/sources.list.d/cloudflare-*.list

	sudo apt update && sudo apt install curl gnupg lsb-release -y

	curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
	echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $VERSION_CODENAME main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list

	sudo apt update -y
	sudo apt install cloudflare-warp -y

	echo -e "${GREEN}Registering WARP client... ${ENDCOLOR}"
	warp-cli registration new

	echo y

	warp-cli mode proxy
	warp-cli connect

	sleep 3

	echo -e "${LIGHT_YELLOW}Checking connection... ${ENDCOLOR}"

	curl --socks5-hostname 127.0.0.1:40000 -s https://www.cloudflare.com/cdn-cgi/trace | grep "warp=on" | while read -r check; do

		if [[ "$check" == "warp=on" ]]; then
			echo -e "${GREEN}Success! WARP is active on 127.0.0.1:40000 ${ENDCOLOR}"
		else
			echo -e "${LIGHT_YELLOW}Warning: WARP installed, but proxy check failed. ${ENDCOLOR}"
		fi
	done

elif [[ "$number" == "2" ]]; then
	echo -e "${GREEN}Deleting cloudflare warp... ${ENDCOLOR}"
	warp-cli disconnect 2>/dev/null
	warp-cli delete 2>/dev/null
	sudo apt remove --purge cloudflare-warp -y
	sudo apt autoremove -y
	rm -rf ~/.cloudflare
	rm -f /etc/apt/sources.list.d/cloudflare-client.list

	sudo systemctl restart systemd-resolved

	echo -e "${GREEN}WARP successfully removed. ${ENDCOLOR}"

elif [[ "$number" == "3" ]]; then
	echo -e "${RED}Exit ${ENDCOLOR}"
	exit 0
else
	echo -e "${RED}Aborted. Invalid option. ${ENDCOLOR}"
	exit 1
fi
