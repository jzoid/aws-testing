#!/bin/bash

if [ "$#" -lt 2 ]; then
  echo "Usage: `basename $0` [root_db_pass] [wp_db_pass]"
  exit 1
fi

root_db_pass=$1
wp_db_pass=$2

# install pkgs
yum install -y vim telnet wget httpd mariadb php php-mysqlnd php-gd bind-utils mariadb-server mariadb rsync

# set up db
yum install -y mariadb-server mariadb
systemctl start mariadb.service
systemctl enable mariadb.service
mysql -e "CREATE DATABASE wordpress;"
mysql -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY '${wp_db_pass}';"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# run mysql secure script
echo -e "\n\n${root_db_pass}\n$root_db_pass\n\n\n\n\n " | mysql_secure_installation

# setup wordpress and start httpd
cd ~
wget http://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
rsync -avP ~/wordpress/ /var/www/html/
mkdir /var/www/html/wp-content/uploads
chown -R apache:apache /var/www/html/*
cd /var/www/html
cp -p wp-config-sample.php wp-config.php
sed -i s/database_name_here/wordpress/ wp-config.php
sed -i s/username_here/wpuser/ wp-config.php
sed -i s/password_here/${wp_db_pass}/ wp-config.php
systemctl start httpd.service
systemctl enable httpd.service
