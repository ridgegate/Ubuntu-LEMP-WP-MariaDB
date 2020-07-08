# Ubuntu-LEMP-Mariadb-Wordpress-bashscript
The following code is a combination of things I have found on the internet and combined them 
for a quick installation script to automate WordPress installation with Nginx, MariaDB (latest), PHP7.4 on Ubuntu 20.04. 

<strong>Credit: </strong>
</br>Lee Wayward @ https://gitlab.com/thecloudorguk/server_install/ 
</br>Jeffrey B. Murphy @ https://www.jbmurphy.com/2015/10/29/bash-script-to-change-the-security-keys-and-salts-in-a-wp-config-php-file/
</br>DigitalOcean: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04

## Instructions
Run the following commands on your Ubuntu terminal to download the script and start the installation. When MariaDB ask for root password, please just press [Enter] to continue. Root password will be auto-generated and entered. The following scripts are shown in sequential order to allow a Wordpress site setup. Second and third steps are optional if you are only creating a test site.</br>
* #### Complete automatic installation (Will still prompt for url and database name/user)
  * wget https://raw.githubusercontent.com/ridgegate/Ubuntu-LEMP-WP-MariaDB/master/quickinstall_noprompt.sh  </br>
  * sudo chmod +x quickinstall_noprompt.sh </br>
  * sudo ./quickinstall_noprompt.sh </br>
* #### To setup SSL with Cloudflare
  * wget https://raw.githubusercontent.com/ridgegate/Ubuntu-LEMP-WP-MariaDB/master/cloudflaressl.sh</br>
  * sudo chmod +x cloudflaressl.sh </br>
  * sudo ./cloudflaressl.sh </br>
* #### Duplicator Setup
  * wget https://raw.githubusercontent.com/ridgegate/Ubuntu-LEMP-WP-MariaDB/master/duplicator.sh  </br>
  * sudo chmod +x duplicator.sh </br>
  * sudo ./duplicator.sh </br>      
## DNS Setting
  * Please make sure you have the correct NS record in your DNS records in your domain registrar.
    * NS record should have the proper NS domain of the hosting company or, if using CloudFlare, CloudFlare's NS nameserver

## Environment
Tested on Ubuntu 20.04(LTS)

## Included Software
* Nginx (Ubuntu repository)
* PHP 7.4 (Ubuntu repository)
* MariaDB (MariaDB repository latest)
* WordPress (Wordpress latest)

