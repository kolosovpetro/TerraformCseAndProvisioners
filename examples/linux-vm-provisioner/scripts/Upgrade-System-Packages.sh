#!/bin/bash

echo "Adding repositories"

sudo DEBIAN_FRONTEND=noninteractive add-apt-repository main -y
sudo DEBIAN_FRONTEND=noninteractive add-apt-repository universe -y
sudo DEBIAN_FRONTEND=noninteractive add-apt-repository restricted -y
sudo DEBIAN_FRONTEND=noninteractive add-apt-repository multiverse -y

echo "Get update package list"

echo "Reload /etc/needrestart/needrestart.conf to avoid interactive mode"

sudo curl -o /etc/needrestart/needrestart.conf https://gist.githubusercontent.com/kolosovpetro/655df0f013e85559f13c42837a25a90e/raw/c98392698e7019d4f9424e8e0a2343e119ba96a9/needrestart.conf
sudo apt-get update && sudo apt-get upgrade -y

echo "Reload daemon outdated packages"
sudo systemctl daemon-reload
