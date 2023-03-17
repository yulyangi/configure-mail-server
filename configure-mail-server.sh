#!/bin/bash

# before mail server installation you need:
# an authoritative DNS server with configured MX record for your domain
# the reverse DNS (PTR record)  needs to be configured as well
# MySQL server as running and the root access to it
# SSL sertificate for your mail server

# change vars accrodingly your MySQL settings
user='mail_admin'
password='mail_admin_password'
dbname='mail'
hosts=127.0.0.1
querry_domain="SELECT domain FROM domains WHERE domain='%s'"
querry_forwardings="SELECT destination FROM forwardings WHERE source='%s'"
querry_mailboxes="SELECT CONCAT(SUBSTRING_INDEX(email,'@',-1),'/',SUBSTRING_INDEX(email,'@',1),'/') FROM users WHERE email='%s'"
querry_email="SELECT email FROM users WHERE email='%s'"

# user and group vars for mail handling
vmailuser=vmail
vmailgroup=vmal

# update the system
apt update

# install the required packages
# during installation you will need to select some interactive requests
# "General mail configuration type" - select "Internet Site"
# "System mail name" - enter your MX on the DNS server like "mail.exemple.com"
apt install postfix postfix-mysql postfix-doc dovecot-common dovecot-imapd dovecot-pop3d libsasl2-2 libsasl2-modules libsasl2-modules-sql sasl2-bin libpam-mysql mailutils dovecot-mysql dovecot-sieve dovecot-managesieved -y

# configure Postfix to comunicate with MySQL
cat<<END> /etc/postfix/mysql_virtual_domains.cf
$user
$password
$dbname
$querry_domain
$hosts
END

cat<<END> /etc/postfix/mysql_virtual_forwardings.cf
$user
$password
$dbname
$querry_forwardings
$hosts
END

cat<<END> /etc/postfix/mysql_virtual_mailboxes.cf
$user
$password
$dbname
$querry_mailboxes
$hosts
END

cat<<END> /etc/postfix/mysql_virtual_email2email.cf
$user
$password
$dbname
$querry_email
$hosts
END

# setting the ownership and permisions
chmod o-rwx /etc/postfix/mysql_virtual_*
chown root.postfix /etc/postfix/mysql_virtual_*

# creat a user and group for mail handling
groupadd -g 5000 $vmailgroup
useradd -g $vmailgroup -u 5000 -d /var/$vmailuser -m $vmailuser
