#!/bin/bash

DOMAIN_NAME=$1
BIND_SERVER_IP=$2
X500_NAME=$3
NFS_EXPORT_PATH=$4

LDAP_SERVER_NAME="ldap."$DOMAIN_NAME

NFS_BASE_USER="erw"
NFS_BASE_GROUP="nfs-users"


# Extend LVM onto unallocated drives (extract from guest customizations)
VGName=$(sudo vgdisplay | grep "VG Name" | sed 's/\s\+VG Name\s\+//')
newdisks=$(ls /dev/sd* | grep -v "/dev/sda")
for newdisk in $newdisks; do
echo "n
p
1


t
8e
w
"| sudo fdisk $newdisk
sudo vgextend $VGName "$newdisk"1
sudo lvresize -l +100%FREE /dev/mapper/$VGName-lv_root
sudo resize2fs /dev/$VGName/lv_root
done

# Overwrite DNS resolver config
echo "nameserver "$BIND_SERVER_IP | sudo tee /etc/resolv.conf

# Configure LDAP authentication
sudo authconfig --enableldap --enableldapauth --ldapserver=$LDAP_SERVER_NAME --ldapbasedn="cn=accounts,"$X500_NAME --enablemkhomedir --update 

# Create data directory, set permissions & ACL and export
sudo mkdir $NFS_EXPORT_PATH
sudo chown $NFS_BASE_USER:$NFS_BASE_GROUP $NFS_EXPORT_PATH
sudo chmod g+ws $NFS_EXPORT_PATH
sudo setfacl -m g::rwx $NFS_EXPORT_PATH
sudo setfacl -dm g::rwx $NFS_EXPORT_PATH
echo $NFS_EXPORT_PATH"           *(rw,sync)" | sudo tee -a /etc/exports

# Adjust netconfig - exclude tcp6 & udp6
sudo sed -i "s/udp6/#udp6/" /etc/netconfig
sudo sed -i "s/tcp6/#tcp6/" /etc/netconfig

# Adjust LDAP group mappings/look-up
echo "filter group  (objectClass=groupofnames)" | sudo tee -a /etc/nslcd.conf
echo "map    group  uniqueMember     member" | sudo tee -a /etc/nslcd.conf

# Restart NSLCD (LDAP name service)
sudo /etc/init.d/nslcd restart

# Set IPTables	
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 111 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 2049 -j ACCEPT' /etc/sysconfig/iptables
sudo iptables-restore /etc/sysconfig/iptables

# Enable and start NFS
sudo chkconfig nfs on
sudo service nfs start

