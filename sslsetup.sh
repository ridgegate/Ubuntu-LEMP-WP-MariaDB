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
echo "Are you using DNS Service such as CloudFlare?"
read -p "Please provide your answer [Y/n] : " DNS_SERVICE
if [[ "$DNS_SERVICE" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
  echo "Please provide CloudFlare Account Email Address"
  read -p "Enter CloudFlare Account Email Address [ENTER] : " CF_ACC_EMAIL
  echo "Please provide CloudFlare Global API Key"
  read -p "Enter CloudFlare API Key: " CF_API_KEY
  touch /root/.config/cloudflare.ini
  echo "dns_cloudflare_email = $CF_ACC_EMAIL" >> /root/.config/cloudflare.ini
  echo "dns_cloudflare_api_key = $CF_API_KEY" >> /root/.config/cloudflare.ini
fi
echo "Setting up LetsEncrypt."
read -t 2
clear

#Install LetsEncrypt Certification Bot
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update && apt-get install certbot python-certbot-nginx -y

if [[ "$DNS_SERVICE" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
    sudo apt install -y python3-certbot-dns-cloudflare
    sudo certbot certonly --dns-cloudflare \
        --dns-cloudflare-credentials /root/.config/cloudflare.ini \
        --server https://acme-v02.api.letsencrypt.org/directory \
        --preferred-challenges dns-01 \
        --rsa-key-size 4096 \
        -d $MY_DOMAIN,*.$MY_DOMAIN
else
   sudo certbot --nginx -d $MY_DOMAIN -d www.$MY_DOMAIN 
fi

 

#--Get the certificates---
sudo certbot --nginx -d $MY_DOMAIN -d www.$MY_DOMAIN
--dns-cloudflare --dns-cloudflare-credentials /root/.secrets/cloudflare.ini -d $MY_DOMAIN,*.$MY_DOMAIN --preferred-challenges dns-01
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
