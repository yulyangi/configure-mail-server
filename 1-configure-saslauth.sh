#!/bin/bash

# declare some vars from MySQL
user='mail_admin'
password='mail_admin_password'
dbname='mail'
host='127.0.0.1'

# create a directory where saslauthd will save its information
mkdir -p /var/spool/postfix/var/run/saslauthd

# edit configuration file of saslauthd /etc/default/saslauthd
sed -i 's|^OPTIONS=.*|OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd -r"|' /etc/default/saslauthd
if ! grep START=yes; then
    echo START=yes >> /etc/default/saslauthd
fi

# create new files
cat<<END> /etc/pam.d/smtp
auth required pam_mysql.so user=$user passwd=$password host=$host db=$dbname table=users usercolumn=email passwdcolumn=password crypt=3 debug
account sufficient pam_mysql.so user=$user passwd=$password host=$host db=$dbname table=users usercolumn=email passwdcolumn=password crypt=3 debug
END

cat<<END> /etc/postfix/sasl/smtpd.conf
pwcheck_method: saslauthd 
mech_list: plain login 
log_level: 4
END

# set the permissions for these files
chmod o-rwx /etc/pam.d/smtp
chmod o-rwx /etc/postfix/sasl/smtpd.conf

# add postfix user to the sasl group
usermod -aG sasl postfix

# restart the services
postfix start
postfix reload
systemctl restart saslauthd
