#!/bin/sh
yum install wget 
wget https://nchc.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.2.5/zabbix-3.2.5.tar.gz
groupadd zabbix -g 201 
useradd -g zabbix -u 201 -m zabbix
tar -xf zabbix-3.2.5.tar.gz
cd zabbix-3.2.5
yum -y install gcc
./configure --prefix=/usr/local/zabbix --sysconfdir=/etc/zabbix/ --enable-agent
make && make install

mkdir /var/log/zabbix
chown zabbix.zabbix /var/log/zabbix 
cp misc/init.d/fedora/core/zabbix_agentd /etc/init.d/ 
chmod 755 /etc/init.d/zabbix_agentd 

ip=$(ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
sed -i "s#BASEDIR=/usr/local#BASEDIR=/usr/local/zabbix#g"  /etc/init.d/zabbix_agentd
sed -i "s/Server\=127.0.0.1/Server\=198.58.99.191/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive\=127.0.0.1/ServerActive\=198.58.99.191:10051/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/Hostname\=Zabbix server/Hostname\=${ip}/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s#tmp/zabbix_agentd.log#var/log/zabbix/zabbix_agentd.log#g" /etc/zabbix/zabbix_agentd.conf

chkconfig zabbix_agentd on 
service zabbix_agentd start
