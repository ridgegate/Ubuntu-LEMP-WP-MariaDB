# sudo ./user.sh
#
clear
echo "Please provide a user name for the system. This prevent brute for ROOT login attempt"
read -p "Type your system user name, then press [ENTER] : " sshuser
echo "Password for user options:"
echo "  * Generate Password [G]"
echo "  * Enter own password [E]"
echo "  * No password required [N]"
read -p "Choose password options : " pwdoption

useradd -m -s /bin/bash $sshuser
usermod -aG sudo $sshuser
if [[ "$pwdoption" =~ ^([gG])+$ ]]; 
then
  sshuserpwd=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-10)
  echo "$sshuser:$sshuserpwd"|chpasswd
elif [[ "$pwdoption" =~ ^([eE])+$ ]]; 
then
  echo "Please enter your password"
  read -p "Please enter your password : " sshuserpwd
  echo "$sshuser:$sshuserpwd"|chpasswd
else
  adduser --disabled-password --shell /bin/bash --gecos "User" $sshuser
fi

echo "Username entered"
echo $sshuser
echo "PWD OPTION SELECTED"
echo $pwdoption
echo "PWD CREATED"
echo $sshuserpwd
