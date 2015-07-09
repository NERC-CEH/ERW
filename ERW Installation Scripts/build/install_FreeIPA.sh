#!/bin/bash

DOMAIN_NAME=$1
REALM=$2
BIND_SERVER_IP=$3
LDAP_SERVER_IP=$4
DM_PASSWORD=$5
ADM_PASSWORD=$6

# Overwrite DNS resolver config
echo "nameserver "$BIND_SERVER_IP | sudo tee /etc/resolv.conf

# Modify /etc/hosts to include FQDN
sudo sed -i 's/ldap/ ldap.'$DOMAIN_NAME'/g' /etc/hosts

# Install FreeIPA packages
sudo yum -y install ipa-server


# Install FreeIPA server unattended
sudo ipa-server-install -r $REALM -n $DOMAIN_NAME -p $DM_PASSWORD -a $ADM_PASSWORD --hostname ldap.$DOMAIN_NAME --ip-address $LDAP_SERVER_IP --no-ntp --idstart=501 --idmax=10000 --no-ssh --no-sshd --selfsign --unattended

# Modify default FreeIPA user configuration
echo $ADM_PASSWORD | sudo kinit admin
sudo ipa config-mod --defaultshell=/bin/bash 
sudo ipa group-add --desc='NFS Users' nfs-users

# Modify iptables
# TCP
# LDAP
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 389 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 636 -j ACCEPT' /etc/sysconfig/iptables
# HTTP
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT' /etc/sysconfig/iptables
# KRB
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 464 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 88 -j ACCEPT' /etc/sysconfig/iptables
# UDP
# KRB
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m udp -p udp --dport 464 -j ACCEPT' /etc/sysconfig/iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m udp -p udp --dport 88 -j ACCEPT' /etc/sysconfig/iptables
sudo iptables-restore /etc/sysconfig/iptables

