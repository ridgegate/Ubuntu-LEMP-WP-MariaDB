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
echo "Please provide a user name for the system. This prevent brute for ROOT login attempt"
read -p "Type your system user name, then press [ENTER] : " sshuser
useradd -m -s /bin/bash $sshuser
usermod -aG sudo $sshuser

PS3="Choose password options : "
select optpwd in "Generate Password" "Enter Password" "No Password" 
do
	case $optpwd in
		"Generate Password")
      sshuserpwd=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-10)
      echo "$sshuser:$sshuserpwd"|chpasswd
      break
			;;
		"Enter Password")
			read -p "Please enter your password : " sshuserpwd
      break
			;;
		"No Password") 
			adduser --disabled-password --shell /bin/bash --gecos "User" $sshuser
      break
			;;		
		*)		
			echo "Error: Please try again (select 1..3)!"
			;;		
	esac
done
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
apt install php-fpm php-mysql php-xml php-mbstring php-common php-curl php-gd php-zip php-soap -y
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
perl -pi -e "s/domain_directory/$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
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

export DEBIAN_FRONTEND=noninteractive
sudo debconf-set-selections <<< "mariadb-server-$MDB_VERSION mysql-server/root_password password PASS"
sudo debconf-set-selections <<< "mariadb-server-$MDB_VERSION mysql-server/root_password_again password PASS"

apt install mariadb-client mariadb-server expect -y
CURRENT_MYSQL_PASSWORD='PASS'
NEW_MYSQL_PASSWORD=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)

if [[ "$MDB_VERSION" < "10.4" ]]
then
    SECURE_MYSQL=$(sudo expect -c "
    set timeout 3
    spawn mysql_secure_installation
    expect \"Enter current password for root (enter for none):\"
    send \"$CURRENT_MYSQL_PASSWORD\r\"
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
  clear
  echo "${SECURE_MYSQL}"
else 
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
  clear
  echo "${SECURE_MYSQL}"
fi


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
sed -i '21idefine('\'WP_MEMORY_LIMIT\'', '\'200M\'');' /var/www/html/$MY_DOMAIN/wp-config.php
sed -i '22idefine('\'WP_MAX_MEMORY_LIMIT\'', '\'256M\'');' /var/www/html/$MY_DOMAIN/wp-config.php

sed -i '23i//Disable Theme Editor' /var/www/html/$MY_DOMAIN/wp-config.php
sed -i '24idefine('\'DISALLOW_FILE_EDIT\'', '\'true\'');' /var/www/html/$MY_DOMAIN/wp-config.php
# -------------------------------------------------------------
TAB_PREF=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)_ #randomize wordpress table prefix
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

# Install WP CLI and Basic Plugins
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
sudo -u www-data wp plugin install --path="/var/www/html/$MY_DOMAIN" woocommerce two-factor-authentication limit-login-attempts-reloaded wps-hide-login onesignal-free-web-push-notifications wordpress-seo

service nginx restart
service php7.2-fpm restart
service mysql restart

# Setting up Firewall
# Reset UFW and enable UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
clear

# Clean UP Unnecessary WordPress Files
sudo rm -rf /root/wordpress
sudo rm -f latest.tar.gz

#Disable Root Login
perl -pi -e "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
mkdir -p /home/$sshuser/.ssh 
cp /root/.ssh/authorized_keys /home/$sshuser/.ssh/authorized_keys
chown $sshuser:$sshuser /home/$sshuser/.ssh/authorized_keys
chown $sshuser:$sshuser /home/$sshuser/.ssh
chmod 700 /home/$sshuser/.ssh && chmod 600 /home/$sshuser/.ssh/authorized_keys

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
echo "Here are System Login Detail"
echo
echo "System Username: $sshuser"
echo "System User Password: $sshuserpwd"
echo "Root login has beeen disabled. Please reconnect with the System user and password."
