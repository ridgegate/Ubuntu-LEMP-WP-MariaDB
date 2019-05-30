#!/bin/bash
#
# Sendmail with gmail

apt-get install sendmail mailutils

mkdir /etc/mail/authinfo
chmod 700 /etc/mail/authinfo
touch /etc/mail/authinfo/smtprelay
echo "AuthInfo: "U:F2BAlert" "I:$F2B_SENDER_EMAIL" "P:F2B_SENDER_PASS"" > /etc/mail/authinfo/smtprelay

makemap hash smtprelay < smtprelay
yes | sendmailconfig

# Set up Postfix
echo "[smtp.gmail.com]:465 $F2B_SENDER_EMAIL:$F2B_SENDER_PASS" > /etc/mail/authinfo

export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< "postfix postfix/mailname string $FQDN_NAME"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

