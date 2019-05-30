#!/bin/bash
# Secure the backend system by disabling ROOT and setup CloudFlare to ban repeated login attempt
#
clear
echo "Please provide a user name for the system. This prevent brute for ROOT login attempt"
read -p "Type your system user name, then press [ENTER] : " sshuser
useradd -m -s /bin/bash $sshuser
usermod -aG sudo $sshuser

PS3="Choose password options : "
select optpwd in "Generate Password" "Enter Password" "No Password" 
do
	case $optpwd in
		"Generate Password")
      sshuserpwd=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-10)
      echo "$sshuser:$sshuserpwd"|chpasswd
      break
			;;
		"Enter Password")
			read -p "Please enter your password : " sshuserpwd
      break
			;;
		"No Password") 
			adduser --disabled-password --shell /bin/bash --gecos "User" $sshuser
      break
			;;		
		*)		
			echo "Error: Please try again (select 1..3)!"
			;;		
	esac
done

#Disable Root Login
perl -pi -e "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
mkdir -p /home/$sshuser/.ssh 
cp /root/.ssh/authorized_keys /home/$sshuser/.ssh/authorized_keys
chown $sshuser:$sshuser /home/$sshuser/.ssh/authorized_keys
chown $sshuser:$sshuser /home/$sshuser/.ssh
chmod 700 /home/$sshuser/.ssh && chmod 600 /home/$sshuser/.ssh/authorized_keys

echo
echo
echo
echo "Here are System Login Detail"
echo
echo "System Username: $sshuser"
echo "System User Password: $sshuserpwd"
echo "Root login has beeen disabled. Please reconnect with the System user and password."
echo
echo
