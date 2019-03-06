#!/bin/bash
# The following code is a combination of things I have found on the internet and combined them 
# for a quick installation script to automate WordPress installation with Nginx, MariaDB 10.1, PHP7.2 on Ubuntu 18.04 Bionics.
# 
# Credit: 
# Lee Wayward @ https://gitlab.com/thecloudorguk/server_install/ 
# Jeffrey B. Murphy @ https://www.jbmurphy.com/2015/10/29/bash-script-to-change-the-security-keys-and-salts-in-a-wp-config-php-file/
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
echo "Please provide a MariaDB version (eg: 10.3 or 10.4)"
read -p "Choose your MariaDB Version [ENTER] : " MDB_VERSION
clear
read -t 30 -p "Thank you. Please press [ENTER] continue or [Control]+[C] to cancel"

#Add MariaDB Repository
sudo apt-get install -y software-properties-common
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo echo "deb [arch=amd64,arm64,ppc64el] http://mirrors.accretive-networks.net/mariadb/repo/$MDB_VERSION/ubuntu bionic main"  | sudo tee -a /etc/apt/sources.list
sudo apt-get update && sudo apt-get upgrade -y

#Install nginx and php7.2
apt install nginx nginx-extras -y
apt install php-fpm php-mysql php-xml php-libsodium php-mbstring php-common php-curl php-gd php-zip php-soap -y
phpenmod mbstring 

#---Following is optional changes to the PHP perimeters that are typically required for WP + Woo themes
perl -pi -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.2/fpm/php.ini
perl -pi -e "s/.*max_execution_time.*/max_execution_time = 120/;" /etc/php/7.2/fpm/php.ini
perl -pi -e "s/.*max_input_time.*/max_input_time = 120/;" /etc/php/7.2/fpm/php.ini
perl -pi -e "s/.*post_max_size.*/post_max_size = 100M/;" /etc/php/7.2/fpm/php.ini
perl -pi -e "s/.*upload_max_filesize.*/upload_max_filesize = 100M/;" /etc/php/7.2/fpm/php.ini
clear
#---Editing Nginx Server Block----
wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript/master/nginx-default-block
mv ./nginx-default-block /etc/nginx/sites-available/$MY_DOMAIN
perl -pi -e "s/domain.com/$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
perl -pi -e "s/www.domain.com/www.$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
sudo ln -s /etc/nginx/sites-available/$MY_DOMAIN /etc/nginx/sites-enabled/
sudo unlink /etc/nginx/sites-enabled/default
clear

# -- Please chang/remove this section according to your needs --
sed -i '43i\\n\t##\n\t# Set Client Body Size\n\t##\n\tclient_body_buffer_size 100M;\n\tclient_max_body_size 100M;\n\n\t##\n\t# Fastcgi Buffer Increase\n\t##\n\tfastcgi_buffers 8 16k;\n\tfastcgi_buffer_size 32k;' /etc/nginx/nginx.conf
clear
#----------------------------------------------------------------

service nginx restart
service php7.2-fpm restart
clear

#export DEBIAN_FRONTEND=noninteractive
#sudo debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password password PASS'
#sudo debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password_again password PASS'

apt install mariadb-client mariadb-server expect -y
CURRENT_MYSQL_PASSWORD=''
NEW_MYSQL_PASSWORD=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)
SECURE_MYSQL=$(sudo expect -c "
set timeout 3
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$CURRENT_MYSQL_PASSWORD\r\"
expect \"Switch to unix_socket authentication \"
send \"n\r\"
expect \"root password?\"
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
clear

#Install WordPress
apt purge expect -y
apt autoremove -y
apt autoclean -y
wget https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
cp ./wordpress/wp-config-sample.php ./wordpress/wp-config.php
touch ./wordpress/.htaccess
chmod 660 ./wordpress/.htaccess
mkdir ./wordpress/wp-content/upgrade
cp -a ./wordpress/. /var/www/html
chown -R www-data /var/www/html
find /var/www/html -type d -exec chmod g+s {} \;
chmod g+w /var/www/html/wp-content
chmod -R g+w /var/www/html/wp-content/themes
chmod -R g+w /var/www/html/wp-content/plugins
clear

#Change wp-config.php data
# -- Please chang/remove this section according to your needs --
sed -i '20i#Define Memory Limit' /var/www/html/wp-config.php
sed -i '21idefine('\'WP_MEMORY_LIMIT\'', '\'200M\'');' /var/www/html/wp-config.php
sed -i '22idefine('\'WP_MAX_MEMORY_LIMIT\'', '\'256M\'');' /var/www/html/wp-config.php
# -------------------------------------------------------------
perl -pi -e "s/database_name_here/$dbname/g" /var/www/html/wp-config.php
perl -pi -e "s/username_here/$dbuser/g" /var/www/html/wp-config.php
perl -pi -e "s/password_here/$userpass/g" /var/www/html/wp-config.php
SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
while read -r SALT; do
SEARCH="define( '$(echo "$SALT" | cut -d "'" -f 2)"
REPLACE=$(echo "$SALT" | cut -d "'" -f 4)
echo "Replacing: $SEARCH"
sed -i "/^$SEARCH/s/put your unique phrase here/$(echo $REPLACE | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')/" /var/www/html/wp-config.php
done <<< "$SALTS"
service nginx restart
service php7.2-fpm restart
service mysql restart

# Setting up Firewall
# Reset UFW and enable UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw delete allow 'Nginx HTTP'
sudo ufw --force enable
clear

# Clean UP Unnecessary WordPress Files
sudo rm -rf /root/wordpress
sudo rm -f latest.tar.gz

echo "WordPress Installed. Please visit your website to continue setup"
echo
echo
echo "Here are your WordPress MySQL database details!"
echo
echo "Database Name: $dbname"
echo "Username: $dbuser"
echo "Password: $userpass"
echo "Your MySQL ROOT Password is: $NEW_MYSQL_PASSWORD"
echo
echo
