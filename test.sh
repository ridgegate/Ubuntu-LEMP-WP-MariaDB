#!/bin/bash
#
echo "Please provide destination email for Fail2Ban Notification"
read -p "Enter destination email, then press [ENTER] : " DEST_EMAIL
echo "$DEST_EMAIL"

sed -i 'f2bdestinationemail/"${DEST_EMAIL}" /etc/fail2ban/jail.local


#perl -pi -e "s/f2bdestinationemail/fsdf\@dsfds.com/;" /etc/fail2ban/jail.local
echo "done"
