#!/bin/bash
#
DEST_EMAIL = 'test@fb.com'
perl -pi -e "s/f2bdestinationemail/$DEST_EMAIL/g;" /etc/fail2ban/jail.local
