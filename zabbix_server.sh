# php
echo '安装php'
rpm -ivh http://repo.webtatic.com/yum/el6/latest.rpm
yum -y install wget gcc php56w php56w-gd php56w-mysql php56w-bcmath php56w-mbstring php56w-xml php56w-ldap
sed -i 's/;date.timezone \=/date.timezone \= Asia\/Shanghai/g' /etc/php.ini
sed -i "s/post_max_size \= 8M/post_max_size \= 32M/g" /etc/php.ini
sed -i "s/max_execution_time \= 30/max_execution_time \= 300/g" /etc/php.ini
sed -i "s/max_input_time \= 60/max_input_time \= 300/g" /etc/php.ini
sed -i "s/;always_populate_raw_post_data \= -1/always_populate_raw_post_data \= -1/g" /etc/php.ini


# mysql
echo '------------install mysql -----------'
yum -y install perl-Time-HiRes perl-TermReadKey perl-Test-Simple jemalloc
wget https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.25-73.1/binary/redhat/6/x86_64/Percona-Server-5.6.25-73.1-r07b797f-el6-x86_64-bundle.tar
tar xvf Percona-Server-5.6.25-73.1-r07b797f-el6-x86_64-bundle.tar
rpm -ivh Percona-Server*.rpm
echo '[client]
host="localhost"
password=""
user="root"' >>/etc/my.cnf
service mysql start
echo '------------mysql install success-----------'

# 依赖
echo '------------install zabbix lib -----------'
echo '安装zabbix 依赖'
yum -y install httpd libxml2-devel net-snmp-devel libcurl-devel
yum -y install epel-release
rpm -Uvh http://nervion.us.es/city-fan/yum-repo/rhel6/x86_64/city-fan.org-release-1-13.rhel6.noarch.rpm
yum -y install libcurl
echo '------------zabbix lib success-----------'


# init data
echo '------------初始化mysql 数据----------'
groupadd  -g 201  zabbix
useradd  -g zabbix  -u 201 -m zabbix
wget https://nchc.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.2.5/zabbix-3.2.5.tar.gz
tar zxvf zabbix-3.2.5.tar.gz
cd zabbix-3.2.5  
/usr/bin/mysql -e "CREATE DATABASE zabbix DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci"
/usr/bin/mysql -D zabbix < database/mysql/schema.sql 
/usr/bin/mysql -D zabbix < database/mysql/images.sql 
/usr/bin/mysql -D zabbix < database/mysql/data.sql 
echo '------------初始化mysql数据完成----------'

# zabbix server
echo '------------安装 zabbix server ----------'
./configure --prefix=/usr/local/zabbix --sysconfdir=/etc/zabbix/ --enable-server --enable-agent --with-net-snmp --with-libcurl --with-mysql --with-libxml2
make && make install
ip=$(ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}') 
sed -i "s/DBUser\=zabbix/DBUser\=root/g" /etc/zabbix/zabbix_server.conf
sed -i "s/# ListenIP\=127.0.0.1/ListenIP\=127.0.0.1,{ip}/g" /etc/zabbix/zabbix_server.conf
ln -s /usr/local/zabbix/sbin/* /usr/bin/
cp misc/init.d/fedora/core/zabbix_* /etc/init.d/ 
chmod +x /etc/init.d/zabbix_*
sed -i "s@BASEDIR=/usr/local@BASEDIR=/usr/local/zabbix@g" /etc/init.d/zabbix_server 

# httpd 
echo '------------安装 httpd ----------'

sed -i '/ServerAdmin root@localhost/a\ServerName {ip}' /etc/httpd/conf/httpd.conf
sed -i '/ServerAdmin root@localhost/a\ServerName 127.0.0.1' /etc/httpd/conf/httpd.conf

mkdir -p /var/www/html/zabbix
cp -r frontends/php/* /var/www/html/zabbix/
chown -R apache.apache /var/www/html/zabbix/
chkconfig zabbix_server on
/etc/init.d/zabbix_server start
service httpd restart
echo '--------zabbix server 安装完成-----------------'
