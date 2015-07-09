#!/bin/bash

BIND_SERVER_IP=$1
PROXY_USERNAME=$2

# Input for public key is broken into components when passed to host
# 3 = identifier, 4 = key, 5 = username
PROXY_PUBLIC_KEY=$3" "$4" "$5

# Overwrite DNS resolver config
echo "nameserver "$BIND_SERVER_IP | sudo tee /etc/resolv.conf

# Remove hosts deny rule
sudo sed -i "s/ALL:ALL/#ALL:ALL/" /etc/hosts.deny

# Create user & home directory, add public SSH key
sudo useradd -m $PROXY_USERNAME
sudo mkdir /home/$PROXY_USERNAME/.ssh
sudo chown $PROXY_USERNAME:$PROXY_USERNAME /home/$PROXY_USERNAME/.ssh
sudo chmod 0700 /home/$PROXY_USERNAME/.ssh
echo $PROXY_PUBLIC_KEY | sudo tee /home/$PROXY_USERNAME/.ssh/authorized_keys
sudo chown $PROXY_USERNAME:$PROXY_USERNAME /home/$PROXY_USERNAME/.ssh/authorized_keys
sudo chmod 0600 /home/$PROXY_USERNAME/.ssh/authorized_keys
