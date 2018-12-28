#!/bin/bash
#
echo "Please provide destination email for Fail2Ban Notification"
read -p "Enter destination email, then press [ENTER] : " DEST_EMAIL
perl -pi -e "s/f2bdestinationemail/q{$DEST_EMAIL}/;" /etc/fail2ban/jail.local
echo "done"
