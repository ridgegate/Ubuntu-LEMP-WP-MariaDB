#!/bin/bash
# This script installs SSL certificate with Letsencrypt and Setup UFW (Firewall) 
#
#
# THIS SCRIPT REQUIRES DNS Records to be setup properly before installing Letsencrypt certbot
#    1. An A record with "my_domain.com" pointing to your server's public IP address.
#    2. An A record with "www.my_domain.com" pointing to your server's public IP address.
#
#
clear
echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
clear

#Reset UFW and enable UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw delete allow 'Nginx HTTP'
sudo ufw enable

#Install LetsEncrypt Certification Bot
sudo add-apt-repository ppa:certbot/certbot
sudo apt install python-certbot-nginx
#--Get the certificates---
sudo certbot --nginx -d $MY_DOMAIN -d www.$MY_DOMAIN

#test to see if auto-renew could be run successfully.
sudo certbot renew --dry-run

echo "LetsEncrypt has installed successfully if renew--dry-run does not"
echo "have any errors. All good to go!"
