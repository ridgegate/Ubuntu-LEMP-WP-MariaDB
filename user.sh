#!/bin/bash
# The default value for PS3 is set to #?.
# Change it i.e. Set PS3 prompt
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
			echo "Error: Please try again (select 1..4)!"
			;;		
	esac
done

echo "Username entered"
echo $sshuser
echo "PWD OPTION SELECTED"
echo $pwdoption
echo "PWD CREATED"
echo $sshuserpwd
