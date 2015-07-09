#!/bin/bash

DOMAIN_NAME=$1
BIND_SERVER_IP=$2
ALFRESCO_SERVER_IP=$3
POSTGRES_PASSWORD=$4
ALFRESCO_DB_PASSWORD=$5

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

# Install Postgres from alternative source
sudo sed -i "0,/extras/s/CentOS\-6/CentOS\-6\nexclude\=postgresql\*/"  /etc/yum.repos.d/CentOS-Base.repo
sudo yum -y localinstall http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-1.noarch.rpm
sudo yum -y install postgresql93-server

# Init database and enable/start service
sudo service postgresql-9.3 initdb
sudo chkconfig postgresql-9.3 on
sudo service postgresql-9.3 start

# Write & execute database init script
echo "ALTER USER postgres PASSWORD '$POSTGRES_PASSWORD';" >> /tmp/db_init.sql
echo "CREATE USER alfresco WITH PASSWORD '$ALFRESCO_DB_PASSWORD';" >> /tmp/db_init.sql
echo "CREATE DATABASE alfresco;" >> /tmp/db_init.sql
echo "GRANT ALL PRIVILEGES ON DATABASE alfresco TO alfresco;" >> /tmp/db_init.sql
sudo -u postgres psql template1 < /tmp/db_init.sql
rm -f /tmp/db_init.sql

# Modify Postgres config
sudo sed -i "s/local   all/#local   all/" /var/lib/pgsql/9.3/data/pg_hba.conf
sudo sed -i "/#local   all/a local     all         postgres      peer\nlocal    all         alfresco      password"  /var/lib/pgsql/9.3/data/pg_hba.conf
sudo sed -i "/IPv4/a host    all             all             $ALFRESCO_SERVER_IP/32         password" /var/lib/pgsql/9.3/data/pg_hba.conf
sudo sed -i "s/#listen/listen/" /var/lib/pgsql/9.3/data/postgresql.conf 
sudo sed -i "s/#port/port/" /var/lib/pgsql/9.3/data/postgresql.conf 
sudo sed -i "s/listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/9.3/data/postgresql.conf 


# Modify iptables
sudo sed -i '/-A INPUT -i lo -j ACCEPT/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 5432 -j ACCEPT' /etc/sysconfig/iptables
sudo iptables-restore /etc/sysconfig/iptables

# Restart service
sudo service postgresql-9.3 restart

