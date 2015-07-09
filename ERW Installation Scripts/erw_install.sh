#!/bin/bash

# Get variables from config file
source erw_install.cfg

# Check subnet (TEMP)
if [ $ORG_NET_SUBNET != '255.255.255.0' ]; then
    echo "invalid subnet mask - >/24"
    exit 1
fi

# Get subnet ID from BIND server addresses
SUBNET_ID=$(echo $BIND_SERVER_IP | awk -F "." '{ print $3 }')

# Config Validation
if [ $(echo $LDAP_SERVER_IP | awk -F "." '{ print $3 }') != $SUBNET_ID ]; then
    echo "LDAP server address invalid"
    exit 1
fi

if [ $(echo $DB_SERVER_IP | awk -F "." '{ print $3 }') != $SUBNET_ID ]; then
    echo "DB server address invalid"
    exit 1
fi

if [ $(echo $ALFRESCO_SERVER_IP | awk -F "." '{ print $3 }') != $SUBNET_ID ]; then
    echo "Alfresco server address invalid"
    exit 1
fi

if [ $(echo $NFS_SERVER_IP | awk -F "." '{ print $3 }') != $SUBNET_ID ]; then
    echo "NFS server address invalid"
    exit 1
fi

if [ $(echo $SYNC_SERVER_IP | awk -F "." '{ print $3 }') != $SUBNET_ID ]; then
    echo "Sync server address invalid"
    exit 1
fi

if [ $(echo $PROXY_SERVER_IP | awk -F "." '{ print $3 }') != $SUBNET_ID ]; then
    echo "Proxy server address invalid"
    exit 1
fi


if [[ ! $NFS_EXPORT_PATH =~ ^/ ]]; then 
    echo "NFS export path must be absolute"
	exit 1
fi

if [[ ! $PROXY_PUBLIC_KEY =~ ^ssh-rsa ]]; then 
    echo "Proxy public key is invalid."
	exit 1
fi



### Set global variables
## Generic items
# DOMAIN_NAME now in config file
INSTALLED=$(date +%Y%m%d)
X500_NAME=$(echo $DOMAIN_NAME | sed -e 's/\./,dc=/g' -e 's/^/dc=/')
## DNS 
ZONE_FILE_PATH="/var/named/"
## LDAP
DM_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
ADM_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
REALM=$(echo $DOMAIN_NAME | awk '{ print toupper($0) }')
# DB
POSTGRES_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
ALFRESCO_DB_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
# ALFRESCO
ALFRESCO_ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)

# Record passwords before remote execution
echo "-- Generated Passwords --" >> install_$INSTALLED.log
echo "FreeIPA:" >> install_$INSTALLED.log
echo "Directory Manager: $DM_PASSWORD" >> install_$INSTALLED.log
echo "Admin: $ADM_PASSWORD" >> install_$INSTALLED.log
echo >> install_$INSTALLED.log
echo "Postgres:" >> install_$INSTALLED.log
echo "Postgres: $POSTGRES_PASSWORD" >> install_$INSTALLED.log
echo "Alfresco: $ALFRESCO_DB_PASSWORD" >> install_$INSTALLED.log
echo >> install_$INSTALLED.log
echo "Alfresco:" >> install_$INSTALLED.log
echo "Admin: $ALFRESCO_ADMIN_PASSWORD" >> install_$INSTALLED.log

echo "Enabling remote execution...."
ssh erw@$BIND_SERVER_IP -t -i ~/.ssh/private_key.rsa 'sudo sed -i "s/requiretty/!requiretty/g" /etc/sudoers'
ssh erw@$LDAP_SERVER_IP -t -i ~/.ssh/private_key.rsa 'sudo sed -i "s/requiretty/!requiretty/g" /etc/sudoers'
ssh erw@$DB_SERVER_IP -t -i ~/.ssh/private_key.rsa 'sudo sed -i "s/requiretty/!requiretty/g" /etc/sudoers'
ssh erw@$ALFRESCO_SERVER_IP -t -i ~/.ssh/private_key.rsa 'sudo sed -i "s/requiretty/!requiretty/g" /etc/sudoers'
ssh erw@$NFS_SERVER_IP -t -i ~/.ssh/private_key.rsa 'sudo sed -i "s/requiretty/!requiretty/g" /etc/sudoers'
ssh erw@$SYNC_SERVER_IP -t -i ~/.ssh/private_key.rsa 'sudo sed -i "s/requiretty/!requiretty/g" /etc/sudoers'
ssh erw@$PROXY_SERVER_IP -t -i ~/.ssh/private_key.rsa 'sudo sed -i "s/requiretty/!requiretty/g" /etc/sudoers'

# Execute BIND build script
ssh erw@$BIND_SERVER_IP -i ~/.ssh/private_key.rsa 'bash -s' < build/install_Bind.sh $INSTALLED $DOMAIN_NAME $ZONE_FILE_PATH $BIND_SERVER_IP $LDAP_SERVER_IP $DB_SERVER_IP $ALFRESCO_SERVER_IP $NFS_SERVER_IP $SYNC_SERVER_IP ${PROXY_SERVER_IP}
echo
read -p "BIND Installation complete. Press [Enter] to continue..."

ssh erw@$LDAP_SERVER_IP -i ~/.ssh/private_key.rsa 'bash -s' < build/install_FreeIPA.sh $DOMAIN_NAME $REALM $BIND_SERVER_IP $LDAP_SERVER_IP $DM_PASSWORD $ADM_PASSWORD
echo
read -p "LDAP Installation complete. Press [Enter] to continue..."

ssh erw@$DB_SERVER_IP -i ~/.ssh/private_key.rsa 'bash -s' < build/install_Postgres.sh $DOMAIN_NAME $BIND_SERVER_IP $ALFRESCO_SERVER_IP $POSTGRES_PASSWORD $ALFRESCO_DB_PASSWORD
echo
read -p "DB Installation complete. Press [Enter] to continue..."

ssh erw@$ALFRESCO_SERVER_IP -i ~/.ssh/private_key.rsa 'bash -s' < build/install_Alfresco.sh $DOMAIN_NAME $X500_NAME $BIND_SERVER_IP $DM_PASSWORD $ALFRESCO_DB_PASSWORD $ALFRESCO_ADMIN_PASSWORD
echo
read -p "ALRESCO Installation complete. Press [Enter] to continue..."

ssh erw@$NFS_SERVER_IP -i ~/.ssh/private_key.rsa 'bash -s' < build/install_NFS.sh $DOMAIN_NAME $BIND_SERVER_IP $X500_NAME $NFS_EXPORT_PATH
echo
read -p "NFS Installation complete. Press [Enter] to continue..."

ssh erw@$SYNC_SERVER_IP -i ~/.ssh/private_key.rsa 'bash -s' < build/install_Sync.sh $DOMAIN_NAME $BIND_SERVER_IP $X500_NAME $NFS_EXPORT_PATH
echo
read -p "CMISSync Installation complete. Press [Enter] to continue..."

ssh erw@$PROXY_SERVER_IP -i ~/.ssh/private_key.rsa 'bash -s' < build/install_Proxy.sh $BIND_SERVER_IP $PROXY_USERNAME $PROXY_PUBLIC_KEY
echo
read -p "SSH Proxy Installation complete. Press [Enter] to continue..."

