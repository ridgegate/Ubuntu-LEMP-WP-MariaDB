# Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript
The following code is a combination of things I have found on the internet and combined them 
for a quick installation script to automate WordPress installation with Nginx, MariaDB 10.3, PHP7.2 on Ubuntu 18.04 Bionics. SSL and firewall setup could be completed with the sslsetup.sh script.

<strong>Credit: </strong>
</br>Lee Wayward @ https://gitlab.com/thecloudorguk/server_install/ 
</br>Jeffrey B. Murphy @ https://www.jbmurphy.com/2015/10/29/bash-script-to-change-the-security-keys-and-salts-in-a-wp-config-php-file/
</br>DigitalOcean: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04

## Instructions
Run the following commands on your Ubuntu terminal to download the script and start the installation. When MariaDB ask for root password, please just press [Enter] to continue. Root password will be auto-generated and entered. The following scripts are shown in sequential order to allow a Wordpress site setup. Second and third steps are optional if you are only creating a test site.</br>
* #### Complete automatic installation (Will still prompt for url and database name/user)
  * wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript/master/quickinstall_noprompt.sh  </br>
  * sudo chmod +x quickinstall_noprompt.sh </br>
  * sudo ./quickinstall_noprompt.sh </br>
* #### To install SSL
  * wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript/master/sslsetup.sh </br>
  * sudo chmod +x sslsetup.sh </br>
  * sudo ./sslsetup.sh </br>
* #### To Fail2Ban and UFW (Firewall)
  * wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript/master/security.sh </br>
  * sudo chmod +x security.sh </br>
  * sudo ./security.sh </br>
* #### Duplicator Setup
  * wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript/master/duplicator.sh  </br>
  * sudo chmod +x duplicator.sh </br>
  * sudo ./duplicator.sh </br>      
## DNS Setting
  * Please make sure you have the correct NS record in your DNS records in your domain registrar.
    * NS record should have the proper NS domain of the hosting company or, if using CloudFlare, CloudFlare's NS nameserver
  * <strong>For example</strong></br>
    * Digital Ocean/GoDaddy/other hosting <strong>without</strong> CloudFlare
      * DNS Records -> NS&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;example.com&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Value: ns1.digitalocean.com&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;TTL: 1800
    * CloudFlare User
      * DNS record in your domain registrar should be pointed to CloudFlare's NS nameserver 
      * All records A/AAA/TXT/MX/ should be set up in CloudFlare even if your server is hosted by other service such as Digital Oceans/GoDaddy.

## Environment
Tested on Ubuntu 18.04 Bionics (LTS)

## Included Software
* Nginx 1.14.0 (Ubuntu repository)
* PHP 7.2 (Ubuntu repository)
* MariaDB 10.3 (MariaDB repository)
* WordPress (Wordpress latest)

