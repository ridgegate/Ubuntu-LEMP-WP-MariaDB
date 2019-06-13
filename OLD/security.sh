#!/bin/bash
# This script Setup Fail2Ban with PostFix
# This requires WP Fail2Ban Plugin
#   https://en-ca.wordpress.org/plugins/wp-fail2ban/
#
# Credit:
# https://www.digitalocean.com/community/tutorials/how-to-protect-an-nginx-server-with-fail2ban-on-ubuntu-14-04
# https://bjornjohansen.no/using-fail2ban-with-wordpress
# https://www.kazimer.com/fail2ban-action-for-cloudflare-rest-api-v4/
#
# Cloudflare API integration with Fail2Ban
# https://guides.wp-bullet.com/integrate-fail2ban-cloudflare-api-v4-guide/
# 
# Basic Fail2Ban Commands
# service fail2ban stop
# service fail2ban start
# 
# fail2ban-client set <jail name> banip <ip>
# fail2ban-client set <jail name> unbanip <ip>
#
# sudo fail2ban-client status <jail name>
#
# sudo iptables -S
#
#
clear
echo "Please provide destination email for Fail2Ban Notification"
read -p "Enter destination email, then press [ENTER] : " F2B_DEST_EMAIL
echo "Please provide sender email for Fail2Ban Notification"
read -p "Enter sender email, then press [ENTER] : " F2B_SENDER_EMAIL
echo "Please provide sender email password"
read -p "Enter sender email, then press [ENTER] : " F2B_SENDER_PASS
echo "Please provide CloudFlare Email Address"
read -p "Enter CloudFlare Account Email Address [ENTER] : " CF_ACC_EMAIL
echo "Please provide CloudFlare Global API Key"
read -p "Enter CloudFlare API Key: " CF_API_KEY
read -p "Do you have multiple URL on the same Cloudflare account? (Y/n):" ZONE_EXIST
if [[ "$ZONE_EXIST" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
    read -p "Enter CloudFlare ZONEID: " CF_ZONEID
fi
echo "Please provide the domain name"
read -p "Enter domain name: " FQDN_NAME
clear
read -t 30 -p "Thank you. Please press [ENTER] continue or [Control]+[C] to cancel"
echo "Setting up Fail2Ban, Postfix and iptables"


sudo apt-get update && sudo apt-get upgrade -y

# Set up Postfix
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< "postfix postfix/mailname string $FQDN_NAME"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

sudo apt-get install libsasl2-modules postfix -y
echo "[smtp.gmail.com]:587 $F2B_SENDER_EMAIL:$F2B_SENDER_PASS" > /etc/postfix/sasl/sasl_passwd
sudo postmap /etc/postfix/sasl/sasl_passwd
sudo chown root:root /etc/postfix/sasl/sasl_passwd.db
sudo chmod 0600 /etc/postfix/sasl/sasl_passwd.db
rm /etc/postfix/sasl/sasl_passwd #remove plain text user & password

# Configure POSTFIX
sudo postconf -e "relayhost = [smtp.gmail.com]:587"
# Enable SASL authentication
sudo postconf -e "smtp_sasl_auth_enable = yes"
sudo postconf -e "smtp_sasl_security_options = noanonymous"
sudo postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl/sasl_passwd"

sudo postconf -e "smtpd_tls_loglevel = 1"
sudo postconf -e "smtpd_use_tls=yes"
sudo postconf -e "smtpd_tls_cert_file = /etc/letsencrypt/live/$FQDN_NAME/fullchain.pem"
sudo postconf -e "smtpd_tls_key_file = /etc/letsencrypt/live/$FQDN_NAME/privkey.pem"
sudo postconf -e "smtpd_tls_ciphers = high"
sudo postconf -e "smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache"

sudo postconf -e "smtp_tls_CAfile = /etc/letsencrypt/live/$FQDN_NAME/cert.pem"
sudo postconf -e "smtp_tls_security_level = encrypt"
sudo postconf -e "smtp_tls_ciphers = high"
sudo postconf -e "smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache"
sudo postconf -e "smtp_tls_wrappermode = yes"

# Allow established connections, traffic generated by the server itself, 
# traffic destined for our SSH and web server ports. 
# https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-ubuntu-14-04
sudo apt-get install -y iptables-persistent
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 25 -j ACCEPT
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo dpkg-reconfigure iptables-persistent -u


## Install Fail2Ban
sudo apt-get install fail2ban -y
wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript/master/resources/jail.local
mv ./jail.local /etc/fail2ban/jail.local
chmod 640 /etc/fail2ban/jail.local

## -- Configure Filters and Jails
sed -i "s/F2B_DEST/$F2B_DEST_EMAIL/" /etc/fail2ban/jail.local
sed -i "s/F2B_SENDER/$F2B_SENDER_EMAIL/" /etc/fail2ban/jail.local
sed -i "s/CF_EMAIL/$CF_ACC_EMAIL/" /etc/fail2ban/jail.local
sed -i "s/CF_GLB_KEY/$CF_API_KEY/" /etc/fail2ban/jail.local
if [[ "$ZONE_EXIST" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
    CF_ZONEID="zones/$CF_ZONEID"
    sed -i "s|CF_ZONE|$CF_ZONEID|g" ./cloudflare-restv4.conf
else
    sed -i "s|CF_ZONE|user|g" ./cloudflare-restv4.conf
fi

# Move/download filter/action to proper location
sudo curl https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMariaDBP-Wordpress-SSL-script/master/resources/cloudflare-restv4.conf > /etc/fail2ban/action.d/cloudflare-restv4.conf
sudo curl https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript/master/resources/auth > /etc/logrotate.d/auth
sudo cp /etc/fail2ban/filter.d/apache-badbots.conf /etc/fail2ban/filter.d/nginx-badbots.conf #enable bad-bots
#sudo curl https://plugins.svn.wordpress.org/wp-fail2ban/trunk/filters.d/wordpress-hard.conf > /etc/fail2ban/filter.d/wordpress-hard.conf
#sudo curl https://plugins.svn.wordpress.org/wp-fail2ban/trunk/filters.d/wordpress-soft.conf > /etc/fail2ban/filter.d/wordpress-soft.conf
#sudo curl https://plugins.svn.wordpress.org/wp-fail2ban/trunk/filters.d/wordpress-extra.conf > /etc/fail2ban/filter.d/wordpress-extra.conf

# Activate Fail2Ban and restart syslog
sudo systemctl service enable fail2ban
sudo systemctl service start fail2ban
sudo service rsyslog restart
echo "Fail2Ban installation completed."
read -t 2
clear

# Modify nginx.conf to include cloudflareip file for the newest ips
touch /etc/nginx/cloudflareip
sed -i '/http {/a\  ' /etc/nginx/nginx.conf #add newline
sed -i '/http {/a\       include /etc/nginx/cloudflareip;' /etc/nginx/nginx.conf
sed -i '/http {/a\       ## Include Cloudflare IP ##' /etc/nginx/nginx.conf
sed -i '/http {/a\  ' /etc/nginx/nginx.conf #add newline
sed -i '/http {/a\  ' /etc/nginx/nginx.conf #add newline

# Get CloudFlare IP and set up cronjob to run automatically
mkdir /root/scripts
wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMariaDBP-Wordpress-SSL-script/master/resources/auto-cf-ip-update.sh
mv ./auto-cf-ip-update.sh /root/scripts/auto-cf-ip-update.sh
sudo chmod +x /root/scripts/auto-cf-ip-update.sh
/bin/bash /root/scripts/auto-cf-ip-update.sh
# Added Cronjob to autoupdate IP list
(crontab -l && echo "# Update CloudFlare IP Ranges (every Sunday at 04:00)") | crontab -
(crontab -l && echo "* 4 * * 0 /bin/bash /root/scripts/auto-cf-ip-update.sh >/dev/null 2>&1") | crontab - 
echo
echo "Done"