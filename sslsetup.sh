#!/bin/bash
# This script installs SSL certificate with Letsencrypt 
#
# THIS SCRIPT REQUIRES DNS Records to be setup properly before installing Letsencrypt certbot
#    1. An A record with "my_domain.com" pointing to your server's public IP address.
#    2. An A record with "www.my_domain.com" pointing to your server's public IP address.
#
#
clear
echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
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
