#!/bin/bash
#
# Sendmail with gmail
#
#


clear
echo "Please provide sender email for Fail2Ban Notification"
read -p "Enter sender email, then press [ENTER] : " F2B_SENDER_EMAIL
echo "Please provide sender email password"
read -p "Enter sender email, then press [ENTER] : " F2B_SENDER_PASS
echo
apt-get update -y
apt-get install -y sendmail mailutils sendmail-bin
mkdir /etc/mail/authinfo
chmod 700 /etc/mail/authinfo
touch /etc/mail/authinfo/smtprelay
echo "AuthInfo: \"U:F2BAlert\" \"I:$F2B_SENDER_EMAIL\" \"P:$F2B_SENDER_PASS\"" > /etc/mail/authinfo/smtprelay
makemap hash  /etc/mail/authinfo/smtprelay <  /etc/mail/authinfo/smtprelay
rm -f /etc/mail/authinfo/smtprelay

# Modify /etc/host to speed up sending
HOSTNAMEVAR=$(</etc/hostname)
perl -pi -e "s/127.0.0.1/127.0.0.1 localhost.localdomain $HOSTNAMEVAR $HOSTNAMEVAR.com/g" /etc/hosts
perl -pi -e "s/HOSTNAME/$HOSTNAMEVAR/g" ~/smtprelayinfo
sed -i '/MAILER_DEFINITIONS/r smtprelayinfo' /etc/mail/sendmail.mc


yes | sendmailconfig

echo "Completed sendmail"
