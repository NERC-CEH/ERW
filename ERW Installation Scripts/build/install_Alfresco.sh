#!/bin/bash

DOMAIN_NAME=$1
X500_NAME=$2
BIND_SERVER_IP=$3
DM_PASSWORD=$4
ALFRESCO_DB_PASSWORD=$5
ALFRESCO_ADMIN_PASSWORD=$6

# X500 with non-legal characters escaped
ESC_X500_NAME=$(echo $X500_NAME | sed -e 's/=/\\=/g')

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

# Install package dependencies 
sudo yum -y install fontconfig libSM libICE libXrender libXext wget

# Get Alfresco installer from alternative source & make executable
wget http://dl.alfresco.com/release/community/5.0.c-build-00145/alfresco-community-5.0.c-installer-linux-x64.bin
chmod +x alfresco-community-5.0.c-installer-linux-x64.bin

# Write unattended config file & install
echo "mode=unattended" >> /tmp/alfresco_unattended.cfg
echo "debuglevel=4" >> /tmp/alfresco_unattended.cfg
echo "enable-components=javaalfresco,alfrescosharepoint,alfrescowcmqs,libreofficecomponent" >> /tmp/alfresco_unattended.cfg
echo "disable-components=postgres" >> /tmp/alfresco_unattended.cfg
echo "jdbc_url=jdbc:postgresql://db.$DOMAIN_NAME/alfresco" >> /tmp/alfresco_unattended.cfg
echo "jdbc_driver=org.postgresql.Driver" >> /tmp/alfresco_unattended.cfg
echo "jdbc_database=alfresco" >> /tmp/alfresco_unattended.cfg
echo "jdbc_username=alfresco" >> /tmp/alfresco_unattended.cfg
echo "jdbc_password=$ALFRESCO_DB_PASSWORD" >> /tmp/alfresco_unattended.cfg 
echo "prefix=/opt/alfresco-5.0" >> /tmp/alfresco_unattended.cfg
echo "alfresco_admin_password=$ALFRESCO_ADMIN_PASSWORD" >> /tmp/alfresco_unattended.cfg
echo "baseunixservice_install_as_service=1" >> /tmp/alfresco_unattended.cfg
sudo ./alfresco-community-5.0.c-installer-linux-x64.bin --optionfile /tmp/alfresco_unattended.cfg
rm -f /tmp/alfresco_unattended.cfg


# Add LDAP auth/sync to global config 
echo "### Authentication ###" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "authentication.chain=alfinst:alfrescoNtlm,ldap1:ldap-ad" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ntlm.authentication.sso.enabled=false" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "# LDAP Auth general" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.authentication.active=true" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.authentication.allowGuestLogin=false" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.authentication.userNameFormat=uid=%s,cn=users,cn=accounts,$X500_NAME" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.authentication.java.naming.provider.url=ldap://ldap.$DOMAIN_NAME:389" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.authentication.java.naming.security.authentication=SIMPLE" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "# LDAP Sync general" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.active=true" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.java.naming.security.authentication=SIMPLE" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.java.naming.security.principal=cn\=Directory\ Manager" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.java.naming.security.credentials=$DM_PASSWORD" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.attributeBatchSize=0" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "# Group sync" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.groupSearchBase=cn\=groups,cn\=accounts,$ESC_X500_NAME" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.groupQuery=(objectClass\=groupofnames)" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.groupType=groupofnames" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.groupIdAttributeName=cn" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.groupMemberAttributeName=member" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "# User sync" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.userSearchBase=cn=users,cn=accounts,$X500_NAME" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.personQuery=(objectClass\=inetorgperson)" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.personType=inetorgperson" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.userIdAttributeName=uid" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.userFirstNameAttributeName=givenName" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.userLastNameAttributeName=sn" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "ldap.synchronization.userEmailAttributeName=mail" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "# Sync" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "synchronization.synchronizeChangesOnly=false" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "synchronization.allowDeletions=true" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "synchronization.import.cron=0 */5 * * * ?" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "# Sync Logging" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "log4j.logger.org.alfresco.repo.importer.ImporterJob=warn" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "log4j.logger.org.alfresco.repo.importer.ExportSourceImporter=warn" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "log4j.logger.org.alfresco.repo.security.authentication.ldap=warn" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "log4j.logger.org.alfresco.repo.security.sync=warn" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "# vCloud SDK Loggin" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties
echo "com.vmware.vcloud=warn" | sudo tee -a /opt/alfresco-5.0/tomcat/shared/classes/alfresco-global.properties

# Start services
sudo service alfresco start

# Modify iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 8085 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 8009 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 8443 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 8180 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 8105 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 8109 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 44100 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 44101 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 50500 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 50501 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 50502 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 50503 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 50504 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 50505 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 50506 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 50507 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 50510 -j ACCEPT' /etc/sysconfig/iptables
sudo iptables-restore /etc/sysconfig/iptables
