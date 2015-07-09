#!/bin/bash

INSTALLED=$1
DOMAIN_NAME=$2
ZONE_FILE_PATH=$3
BIND_SERVER_IP=$4
LDAP_SERVER_IP=$5
DB_SERVER_IP=$6
ALFRESCO_SERVER_IP=$7
NFS_SERVER_IP=$8
SYNC_SERVER_IP=$9
PROXY_SERVER_IP=${10}


# Local variables
FORWARD_ZONE_NAME=$DOMAIN_NAME
REVERSE_ZONE_NAME=$(echo $BIND_SERVER_IP | awk -F "." '{ print $3 }')"."$(echo $BIND_SERVER_IP | awk -F "." '{ print $2 }')"."$(echo $BIND_SERVER_IP | awk -F "." '{ print $1 }')".in-addr.arpa"


# Install BIND
sudo yum -y install bind


# Build forward lookup zone file
sudo touch "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "\$TTL 86400" | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "@	IN	SOA	ns1."$DOMAIN_NAME". root."$DOMAIN_NAME". (" | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "		"$INSTALLED"00	;Serial - YYYYMMDDvv" | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "		3600    ;Refresh" | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "		1800    ;Retry" | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "		604800  ;Expire" | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "		86400   ;Minimum TTL" | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo ")" | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "          NS  @" | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "@         IN  A        "$BIND_SERVER_IP  | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "ns1       IN  CNAME    bind."$DOMAIN_NAME"." | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "bind      IN  A        "$BIND_SERVER_IP | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "ldap      IN  A        "$LDAP_SERVER_IP | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "db        IN  A        "$DB_SERVER_IP | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "alfresco  IN  A        "$ALFRESCO_SERVER_IP | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "nfs       IN  A        "$NFS_SERVER_IP | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "sync       IN  A        "$SYNC_SERVER_IP | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"
echo "proxy       IN  A        "$PROXY_SERVER_IP | sudo tee -a "$ZONE_FILE_PATH$FORWARD_ZONE_NAME"


# Build reverse lookup zone file
sudo touch "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo "\$ORIGIN "$REVERSE_ZONE_NAME"." | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo "\$TTL 86400" | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo "@	IN	SOA	ns1."$DOMAIN_NAME". root."$DOMAIN_NAME". (" | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo "		"$INSTALLED"	;Serial" | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo "		3600	;Refresh" | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo "		1800	;Retry" | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo "		604800	;Expire" | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo "		86400	;Minimum TTL" | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo ")" | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo "		IN	NS	bind."$DOMAIN_NAME"." | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo $(echo $BIND_SERVER_IP | awk -F "." '{ print $4 }')"	IN	PTR	bind."$DOMAIN_NAME"." | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo $(echo $LDAP_SERVER_IP | awk -F "." '{ print $4 }')"	IN	PTR	ldap."$DOMAIN_NAME"." | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo $(echo $DB_SERVER_IP | awk -F "." '{ print $4 }')"	IN	PTR	db."$DOMAIN_NAME"." | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo $(echo $ALFRESCO_SERVER_IP | awk -F "." '{ print $4 }')"	IN	PTR	alfresco."$DOMAIN_NAME"." | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo $(echo $NFS_SERVER_IP | awk -F "." '{ print $4 }')"	IN	PTR	nfs."$DOMAIN_NAME"." | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo $(echo $SYNC_SERVER_IP | awk -F "." '{ print $4 }')"	IN	PTR	sync."$DOMAIN_NAME"." | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"
echo $(echo $PROXY_SERVER_IP | awk -F "." '{ print $4 }')"	IN	PTR	proxy."$DOMAIN_NAME"." | sudo tee -a "$ZONE_FILE_PATH$REVERSE_ZONE_NAME"


# Modify /etc/named.conf
sudo sed -i 's/listen-on port 53 { 127.0.0.1; }/listen-on port 53 { '$BIND_SERVER_IP'; }/g' /etc/named.conf
sudo sed -i 's/listen-on-v6/#listen-on-v6/g' /etc/named.conf
sudo sed -i 's/allow-query     { localhost; }/allow-query     { any; }/g' /etc/named.conf
sudo sed -i '/recursion yes;/a \        forwarders { 8.8.8.8; };' /etc/named.conf

echo "       zone \""$FORWARD_ZONE_NAME"\" IN {" | sudo tee -a /etc/named.conf
echo "            type master;" | sudo tee -a /etc/named.conf
echo "            file \""$FORWARD_ZONE_NAME"\";" | sudo tee -a /etc/named.conf
echo "            allow-update { none; };" | sudo tee -a /etc/named.conf
echo "       };" | sudo tee -a /etc/named.conf
   
echo "       zone \""$REVERSE_ZONE_NAME"\" IN {" | sudo tee -a /etc/named.conf
echo "            type master;" | sudo tee -a /etc/named.conf
echo "            file \""$REVERSE_ZONE_NAME"\";" | sudo tee -a /etc/named.conf
echo "            allow-update { none; };" | sudo tee -a /etc/named.conf
echo "       };" | sudo tee -a /etc/named.conf

# Modify iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m udp -p udp --dport 53 -j ACCEPT' /etc/sysconfig/iptables
sudo iptables-restore /etc/sysconfig/iptables

# Enable on boot
sudo chkconfig named on

# Start bind
sudo service named start

