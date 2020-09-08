#!/bin/bash
# The following code is a combination of things I have found on the internet and combined them 
# for a quick installation script to automate WordPress installation with Nginx, MariaDB, PHP on Ubuntu 20.04.
# 
# Credit: 
# Lee Wayward @ https://gitlab.com/thecloudorguk/server_install/ 
# Jeffrey B. Murphy @ https://www.jbmurphy.com/2015/10/29/bash-script-to-change-the-security-keys-and-salts-in-a-wp-config-php-file/
# https://gulshankumar.net/install-wordpress-with-lemp-on-ubuntu-18-04/
#
# Instruction
# Run the following commands 
# sudo chmod +x quickinstallscript.sh
# sudo ./quickinstallscript.sh
#
clear
echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
echo "Please provide a name for the DATABASE"
read -p "Type your database name, then press [ENTER] : " dbname
echo "Please provide a DATABASE username"
read -p "Type your database username, then press [ENTER] : " dbuser


#MY_DOMAIN=sprrivets.com
#dbname=testdb
#dbuser=dbuser

#echo $MY_DOMAIN
#echo $dbname
#echo $dbuser
read -t 30 -p "Thank you. Please press [ENTER] continue or [Control]+[C] to cancel"


#Add repositories
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository universe
#Add MariaDB Repository with the latest MariaDB version
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

DEBIAN_FRONTEND=noninteractive sudo apt-get update && sudo apt upgrade -y && sudo apt dist-upgrade && sudo apt autoclean && sudo apt autoremove -y 

#Install nginx and php7.4 on Ubuntu 20.04 LTS
apt install -y nginx nginx-extras 
apt install -y php-fpm php-mysql php-intl php-xml php-xmlrpc php-mbstring php-common php-curl php-gd php-zip php-soap php-mbstring

SERVERIP=$(curl https://ipinfo.io/ip)

#---Following is optional changes to the PHP perimeters that are typically required for WP + Woo themes
perl -pi -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.4/fpm/php.ini
perl -pi -e "s/.*max_execution_time.*/max_execution_time = 120/;" /etc/php/7.4/fpm/php.ini
perl -pi -e "s/.*max_input_time.*/max_input_time = 3000/;" /etc/php/7.4/fpm/php.ini
perl -pi -e "s/.*post_max_size.*/post_max_size = 100M/;" /etc/php/7.4/fpm/php.ini
perl -pi -e "s/.*upload_max_filesize.*/upload_max_filesize = 200M/;" /etc/php/7.4/fpm/php.ini
perl -pi -e "s/memory_limit = 128M/memory_limit = 328M/g" /etc/php/7.4/fpm/php.ini

#---Editing Nginx Server Block----
wget https://raw.githubusercontent.com/ridgegate/Ubuntu-LEMP-WP-MariaDB/master/NGINXFiles/nginx-default-block
mv ./nginx-default-block /etc/nginx/sites-available/$MY_DOMAIN
wget https://raw.githubusercontent.com/ridgegate/Ubuntu-LEMP-WP-MariaDB/master/NGINXFiles/restrictions.conf
mkdir /etc/nginx/restrictions
mv ./restrictions.conf /etc/nginx/restrictions/serverblock_restrictions.conf
touch /var/www/html/$MY_DOMAIN/nginx.conf
perl -pi -e "s/domain.com/$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
perl -pi -e "s/www.domain.com/www.$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
perl -pi -e "s/publicip/$SERVERIP/g" /etc/nginx/sites-available/$MY_DOMAIN
perl -pi -e "s/domain_directory/$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
sudo ln -s /etc/nginx/sites-available/$MY_DOMAIN /etc/nginx/sites-enabled/
sudo unlink /etc/nginx/sites-enabled/default


# -- Please chang/remove this section according to your needs --
sed -i '43i\\n\t##\n\t# Client Body Size\n\t##\n\tclient_body_buffer_size 10K;\n\tclient_max_body_size 40M;\n\n\t##\n\t# Fastcgi Buffer Increase\n\t##\n\tfastcgi_buffers 8 16k;\n\tfastcgi_buffer_size 32k;\n\n\t##\n\t#Set Header Buffer Size\n\t##\n\tclient_header_buffer_size 1k;\n\tlarge_client_header_buffers 2 1k;\n\n\t##\n\t#Time Outs Settings\n\t##\n\tclient_body_timeout 12;\n\tclient_header_timeout 12;\n\tsend_timeout 10;' /etc/nginx/nginx.conf
perl -pi -e "s/keepalive_timeout 65/keepalive_timeout 15/g" /etc/nginx/nginx.conf
perl -pi -e "s/# gzip_proxied any/gzip_proxied expired no-cache no-store private auth/g" /etc/nginx/nginx.conf
perl -pi -e "s/# gzip_comp_level 6/gzip_comp_level 4/g" /etc/nginx/nginx.conf
wget https://raw.githubusercontent.com/ridgegate/Ubuntu-LEMP-WP-MariaDB/master/NGINXFiles/gzipsettings.conf
mv ./gziptypes.conf /etc/nginx/conf.d

#----------------------------------------------------------------

service nginx restart && systemctl restart php7.4-fpm.service 

cho "Installing MariaDB"
sudo apt-get install mariadb-server galera-4 mariadb-client libmariadb3 mariadb-backup mariadb-common expect -y
CURRENT_MYSQL_PASSWORD='PASS'
NEW_MYSQL_PASSWORD=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)

#Secure MariaDB with mysql_secure_installation
SECURE_MYSQL=$(sudo expect -c "
set timeout 3
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"\r\"
expect \"Switch to unix_socket authentication \"
send \"n\r\"
expect \"Change the root password?\"
send \"y\r\"
expect \"New password:\"
send \"$NEW_MYSQL_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$NEW_MYSQL_PASSWORD\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "${SECURE_MYSQL}"

# Create WordPress MySQL database
userpass=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)
echo "CREATE DATABASE $dbname;" | sudo mysql -u root -p$NEW_MYSQL_PASSWORD
echo "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$userpass';" | sudo mysql -u root -p$NEW_MYSQL_PASSWORD
echo "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';" | sudo mysql -u root -p$NEW_MYSQL_PASSWORD
echo "FLUSH PRIVILEGES;" | sudo mysql -u root -p$NEW_MYSQL_PASSWORD
echo "delete from mysql.user where user='mysql';" | sudo mysql -u root -p$NEW_MYSQL_PASSWORD


#Install WordPress
apt purge expect -y
apt autoremove -y
apt autoclean -y
wget https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
cp ./wordpress/wp-config-sample.php ./wordpress/wp-config.php
mkdir ./wordpress/wp-content/upgrade
mkdir /var/www/html/$MY_DOMAIN
cp -a ./wordpress/. /var/www/html/$MY_DOMAIN
chown -R www-data /var/www/html/$MY_DOMAIN

find /var/www/html/$MY_DOMAIN -type d -exec chmod g+s {} \;
chmod g+w /var/www/html/$MY_DOMAIN/wp-content
chmod -R g+w /var/www/html/$MY_DOMAIN/wp-content/themes
chmod -R g+w /var/www/html/$MY_DOMAIN/wp-content/plugins
clear

#Change wp-config.php data
# -- Please chang/remove this section according to your needs --
sed -i '20i//Define Memory Limit' /var/www/html/$MY_DOMAIN/wp-config.php
sed -i '21idefine('\'WP_MEMORY_LIMIT\'', '\'256M\'');' /var/www/html/$MY_DOMAIN/wp-config.php
sed -i '22idefine('\'WP_MAX_MEMORY_LIMIT\'', '\'320M\'');' /var/www/html/$MY_DOMAIN/wp-config.php
sed -i '23i//Disable Theme Editor' /var/www/html/$MY_DOMAIN/wp-config.php
sed -i '24idefine('\'DISALLOW_FILE_EDIT\'', '\'true\'');' /var/www/html/$MY_DOMAIN/wp-config.php
sed -i '23i//Disable Theme Editor' /var/www/html/$MY_DOMAIN/wp-config.php
sed -i '24idefine('\'WP_POST_REVISIONS\'', '\'5\'');' /var/www/html/$MY_DOMAIN/wp-config.php
# -------------------------------------------------------------
#randomize wordpress table prefix to make hacking harder
TAB_PREF=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)_ 
perl -pi -e "s/wp_/$TAB_PREF/g" /var/www/html/$MY_DOMAIN/wp-config.php
perl -pi -e "s/database_name_here/$dbname/g" /var/www/html/$MY_DOMAIN/wp-config.php
perl -pi -e "s/username_here/$dbuser/g" /var/www/html/$MY_DOMAIN/wp-config.php
perl -pi -e "s/password_here/$userpass/g" /var/www/html/$MY_DOMAIN/wp-config.php
SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
while read -r SALT; do
SEARCH="define( '$(echo "$SALT" | cut -d "'" -f 2)"
REPLACE=$(echo "$SALT" | cut -d "'" -f 4)
echo "Replacing: $SEARCH"
sed -i "/^$SEARCH/s/put your unique phrase here/$(echo $REPLACE | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')/" /var/www/html/$MY_DOMAIN/wp-config.php
done <<< "$SALTS"
service nginx restart
service php7.4-fpm restart
service mysql restart

# Securing System & wp-config
# Reset UFW and enable UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable


#Disable Password SSH login
perl -pi -e "s/PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config

# Clean UP Unnecessary WordPress Files
sudo rm -rf /root/wordpress
sudo rm -f latest.tar.gz
sudo rm -f /etc/nginx/sites-available/default
clear

echo "WordPress Installed. Please visit your website to continue setup"
echo
echo
echo "Here are your WordPress MySQL database details!"
echo
echo "Database Name: $dbname"
echo "Database Username: $dbuser"
echo "Database User Password: $userpass"
echo "Your MySQL ROOT Password is: $NEW_MYSQL_PASSWORD"
echo
echo
