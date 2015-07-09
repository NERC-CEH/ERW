#!/bin/bash

DOMAIN_NAME=$1
BIND_SERVER_IP=$2
X500_NAME=$3
NFS_EXPORT_PATH=$4

LDAP_SERVER_NAME="ldap."$DOMAIN_NAME


# Extend LVM onto unallocated drives (extract from guest customizations)
newdisks=$(ls /dev/sd* | grep -v "/dev/sda")
for newdisk in $newdisks; do
echo "n
p
1


t
8e
w
"| sudo fdisk $newdisk
sudo vgextend ubuntu-vg "$newdisk"1
sudo lvresize -l +100%FREE /dev/mapper/ubuntu--vg-root
sudo resize2fs /dev/ubuntu-vg/root
done


echo "nameserver "$BIND_SERVER_IP | sudo tee /etc/resolvconf/resolv.conf.d/base
sudo service resolvconf restart

sudo apt-add-repository -y ppa:ubuntu-mate-dev/ppa
sudo apt-add-repository -y ppa:ubuntu-mate-dev/trusty-mate
sudo apt-get update
sudo apt-get -y upgrade

# Install common components
sudo apt-get -y install portmap nfs-common nfs-server

# Configure NFS Server
echo "/home         *(rw,insecure,no_subtree_check,async)" | sudo tee /etc/exports
sudo service nfs-kernel-server restart

# Install & configure LDAP client
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install auth-client-config libnss-ldap
echo "###DEBCONF###" | sudo tee /etc/ldap.conf
echo "base cn=accounts,"$X500_NAME | sudo tee -a /etc/ldap.conf
echo "uri ldap://ldap."$DOMAIN_NAME | sudo tee -a /etc/ldap.conf
echo "ldap_version 3" | sudo tee -a /etc/ldap.conf 
echo "        required                        pam_mkhomedir.so skel=/etc/skel umask=0077" | sudo tee -a /usr/share/pam-configs/ldap 
sudo DEBIAN_FRONTEND=noninteractive auth-client-config -t nss -p lac_ldap
sudo DEBIAN_FRONTEND=noninteractive pam-auth-update 

# Install remote desktop components
sudo apt-get -y install xrdp ubuntu-mate-core ubuntu-mate-desktop
echo 'mate-session' | sudo tee /etc/skel/.xsession

# Install CMISSync & pre-reqs 
sudo apt-get -y install libappindicator0.1-cil-dev gtk-sharp2 mono-runtime mono-devel monodevelop libndesk-dbus1.0-cil-dev nant libnotify-cil-dev libgtk2.0-cil-dev mono-mcs mono-gmcs libwebkit-cil-dev intltool libtool libndesk-dbus-glib1.0-cil-dev liblog4net-cil-dev libnewtonsoft-json-cil-dev gvfs git
wget https://github.com/NERC-CEH/ERW-Tools/raw/master/SyncUtil/cmissync_2.0-0.deb
sudo dpkg -i cmissync_2.0-0.deb

