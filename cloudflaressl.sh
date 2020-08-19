
#!/bin/bash
# This script installs SSL certificate with Cloudflare Generated SSL 
#
# THIS SCRIPT REQUIRES DNS Records to be setup properly before installing Letsencrypt certbot
#    1. An A record with "my_domain.com" pointing to your server's public IP address.
#    2. An A record with "www.my_domain.com" pointing to your server's public IP address.
#
#
clear
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
echo "Copy the private key and enter below"
read -p "Paste your private key " MY_DOMAIN_PRV_KEY
echo $MY_DOMAIN_PRV_KEY > /etc/ssl/private/$MY_DOMAIN_key.pem
echo 
echo
echo "Thank you. Now copy the Origin Certificate section and paste it below"
read -p "Paste your Origin Certificate key " MY_DOMAIN_ORG_CERT
echo $MY_DOMAIN_ORG_CERT > /etc/ssl/private/$MY_DOMAIN_cert.pem
echo 
echo "Thank you. Sit tight while we change things in the background"
echo
echo
SERVERIP=$(curl https://ipinfo.io/ip)
wget -O /etc/ssl/private/cloudflareoa.pem https://support.cloudflare.com/hc/article_attachments/360037898732/origin_ca_ecc_root.pem
wget https://raw.githubusercontent.com/ridgegate/Ubuntu-LEMP-WP-MariaDB/master/NGINXFiles/nginx-ssl-block
cp -f ./nginx-ssl-block /etc/nginx/sites-available/$MY_DOMAIN
perl -pi -e "s/domain.com/$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
perl -pi -e "s/www.domain.com/www.$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
perl -pi -e "s/publicip/$SERVERIP/g" /etc/nginx/sites-available/$MY_DOMAIN
perl -pi -e "s/domain_directory/$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
echo "Thank you. Done!"
