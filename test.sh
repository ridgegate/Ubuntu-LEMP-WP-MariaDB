#!/bin/bash
#
echo "Please provide destination email for Fail2Ban Notification"
read -p "Enter destination email, then press [ENTER] : " DEST_EMAIL
perl -pi -e "s/f2bdestinationemail/\Q$DEST_EMAIL\E/g;" /etc/fail2ban/jail.local
echo "done"
