#!/bin/bash
# This script installs SSL certificate with Letsencrypt and Setup UFW (Firewall) 
#
#
# THIS SCRIPT REQUIRES DNS Records to be setup properly before installing Letsencrypt certbot
#    1. An A record with "my_domain.com" pointing to your server's public IP address.
#    2. An A record with "www.my_domain.com" pointing to your server's public IP address.
#
#
# Credit:
# https://www.digitalocean.com/community/tutorials/how-to-protect-an-nginx-server-with-fail2ban-on-ubuntu-14-04
#
clear
echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
echo "Please provide destination email for Fail2Ban Notification"
read -p "Enter destination email, then press [ENTER] : " DEST_EMAIL
echo "Please provide sender email for Fail2Ban Notification"
read -p "Enter sender email, then press [ENTER] : " ORG_EMAIL
clear
echo "Setting up Fail2Ban and required files"
sudo apt-get update -y
sudo apt-get install -y sendmail iptables-persistent
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo dpkg-reconfigure iptables-persistent -u

## Install Fail2Ban
sudo apt-get install fail2ban -y
wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript/master/f2b-conf/jail.local
mv ./jail.local /etc/fail2ban/jail.local
perl -pi -e "s/f2bdestinationemail/$DEST_EMAIL/g;" /etc/fail2ban/jail.local
perl -pi -e "s/f2bsenderemail/$ORG_EMAIL/g;" /etc/fail2ban/jail.local
## Configure Filters and Jails
sudo cp /etc/fail2ban/conf.d/apache-badbots.conf /etc/fail2ban/conf.d/nginx-badbots.conf #enable bad-bots
sudo service fail2ban start
# https://www.tricksofthetrades.net/2018/05/18/fail2ban-installing-bionic/
# https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-ubuntu-14-04
echo "Done Fail2Ban"
read -t 2
#clear
echo "Setting up firewall"
read -t 2
#Reset UFW and enable UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw delete allow 'Nginx HTTP'
sudo ufw enable
echo
echo
echo "Completed Firewall Setup. Setting up LetsEncrypt."
read -t 2
clear
#Install LetsEncrypt Certification Bot
sudo add-apt-repository ppa:certbot/certbot
sudo apt install -y python-certbot-nginx
#--Get the certificates---
sudo certbot --nginx -d $MY_DOMAIN -d www.$MY_DOMAIN
echo
echo
echo
echo
echo "LetsEncrypt is installed and should be successfully activated"
echo
echo
read -t 30 -p "Please press [ENTER] continue to test auto-renew with --dry-run or [Control]+[C] to cancel"
clear
#test to see if auto-renew could be run successfully.
sudo certbot renew --dry-run
echo
echo
echo
echo "LetsEncrypt dry-run completed. Check for errors."
