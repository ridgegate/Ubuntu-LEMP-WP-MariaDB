echo "Install LetsEncrypt SSL with CloudFlare DNS"
echo "Please provide your CloudFlare email"
read -p "Type your CloudFlare email, then press [ENTER] : " cfemail
echo "Please provide your CloudFlare Global API Key"
read -p "Type your CloudFlare Global API Key, then press [ENTER] : " cfapi
echo

#---- Wildcard SSL with Cloudflare---#
#--Create your Cloudflare Credential Files--#
mkdir -p /root/.secrets/
printf '%s' 'dns_cloudflare_email = "' $cfemail '"'  > /root/.secrets/cloudflare.ini
printf '%s\n' >> /root/.secrets/cloudflare.ini
printf '%s' 'dns_cloudflare_api_key = "' $cfapi '"'  >> /root/.secrets/cloudflare.ini
sudo chmod 0400 /root/.secrets/cloudflare.ini
#--Install Certbot--#
sudo apt-get install certbot python3-certbot-nginx python3-certbot-dns-cloudflare
sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.secrets/cloudflare.ini -d $MY_DOMAIN,*.$MY_DOMAIN --preferred-challenges dns-01
(crontab -l ; echo '14 5 * * * /usr/bin/certbot renew --quiet --post-hook "/usr/sbin/service nginx reload" > /dev/null 2>&1') | crontab -
certbot renew --dry-run
read -t 60 -p "Please ensure certbot renewal is completed successfully and press [ENTER] to continue or [Control]+[C] to cancel"
