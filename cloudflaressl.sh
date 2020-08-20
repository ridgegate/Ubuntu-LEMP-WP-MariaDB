
#!/bin/bash
# This script installs SSL certificate with Cloudflare Generated SSL 
#
# THIS SCRIPT REQUIRES DNS Records to be setup properly before installing Letsencrypt certbot
#    1. An A record with "my_domain.com" pointing to your server's public IP address.
#    2. An A record with "www.my_domain.com" pointing to your server's public IP address.
#
#
clear
# Create Necessary Folders
mkdir /etc/ssl/private
mkdir /etc/nginx/private
#------

echo "This require Cloudflare account"
echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
echo "Thank you. Please follow the following instruction in detail"
echo "Step 1: Generate Origin Certificate for your domain in Cloudflare"
echo "        Go to domain->SSL/TLS->Origin Server"
echo "        Section Origin Certificate & click Create Certificate"
echo "        Options:"
echo "            - Private Key Type ECDSA"
echo "            - Any hostnames that you like"
echo "            - Certificate Validity - Select any period you like"
echo " **!!! DO NOT Close the following window with Private KEY until the last step !!!*****"
read -p "Copy the private key and paste into nano. Once pasted, press [CTRL]+X to exit and save the changes. Press [Enter] when ready to paste."
touch /etc/ssl/private/${MY_DOMAIN}_key.pem
nano /etc/ssl/private/${MY_DOMAIN}_key.pem
echo
echo "Thank you."
read -p "Copy the certificate and paste into nano. Once pasted, press [CTRL]+X to exit and save the changes. Press [Enter] when ready to paste."
touch /etc/ssl/private/${MY_DOMAIN}_cert.pem
nano /etc/ssl/private/${MY_DOMAIN}_cert.pem
echo 
echo "Thank you. Sit tight while we change things in the background"
echo
echo

SERVERIP=$(curl https://ipinfo.io/ip)


wget -O /etc/nginx/private/restrictions.conf https://raw.githubusercontent.com/ridgegate/Ubuntu-LEMP-WP-MariaDB/master/NGINXFiles/restrictions.conf
wget -O /etc/ssl/private/cloudflareoa_cert.pem https://support.cloudflare.com/hc/article_attachments/360037898732/origin_ca_ecc_root.pem
wget -O /etc/nginx/sites-available/$MY_DOMAIN https://raw.githubusercontent.com/ridgegate/Ubuntu-LEMP-WP-MariaDB/master/NGINXFiles/nginx-ssl-block
perl -pi -e "s/domain.com/$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
perl -pi -e "s/www.domain.com/www.$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
perl -pi -e "s/publicip/$SERVERIP/g" /etc/nginx/sites-available/$MY_DOMAIN
perl -pi -e "s/domain_directory/$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN

service nginx restart
service php7.4-fpm restart
service mysql restart

echo "Thank you. Done!"
