#!/bin/bash

# before mail server installation you need:
# an authoritative DNS server with configured MX record for your domain
# the reverse DNS (PTR record) needs to be configured as well
# MySQL server as running and the root access to it
# SSL or TLS sertificate for your mail server

# change vars accordingly your MySQL settings
user='mail_admin'
password='mail_admin_password'
dbname='mail'
hosts='127.0.0.1'
querry_domain="SELECT domain FROM domains WHERE domain='%s'"
querry_forwardings="SELECT destination FROM forwardings WHERE source='%s'"
querry_mailboxes="SELECT CONCAT(SUBSTRING_INDEX(email,'@',-1),'/',SUBSTRING_INDEX(email,'@',1),'/') FROM users WHERE email='%s'"
querry_email="SELECT email FROM users WHERE email='%s'"

# user and group vars for mail handling
vmailuser='vmail'
vmailgroup='vmail'

# some others vars
mydomain='binbash.site'

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

# create a user and group for mail handling
groupadd -g 5000 $vmailgroup
useradd -g $vmailgroup -u 5000 -d /var/$vmailuser -m $vmailuser

# configure postfix
postconf -e "myhostname = mail.$mydomain"
postconf -e "mydestination = mail.$mydomain, localhost, localhost.localdomain"
postconf -e "mynetworks = 127.0.0.0/8"
postconf -e "message_size_limit = 31457280"
postconf -e "virtual_alias_domains ="
postconf -e "virtual_alias_maps = proxy:mysql:/etc/postfix/mysql_virtual_forwardings.cf, mysql:/etc/postfix/mysql_virtual_email2email.cf"
postconf -e "virtual_mailbox_domains = proxy:mysql:/etc/postfix/mysql_virtual_domains.cf"
postconf -e "virtual_mailbox_maps = proxy:mysql:/etc/postfix/mysql_virtual_mailboxes.cf"
postconf -e "virtual_mailbox_base = /var/$vmailuser"
postconf -e "virtual_uid_maps = static:5000"
postconf -e "virtual_gid_maps = static:5000"
postconf -e "smtpd_sasl_auth_enable = yes"
postconf -e "broken_sasl_auth_clients = yes"
postconf -e "smtpd_sasl_authenticated_header = yes"
postconf -e "smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination"
postconf -e "smtpd_use_tls = yes"
# here is the path to the cert and key files of TLS encryption of your domain
postconf -e "smtpd_tls_cert_file = /etc/letsencrypt/live/$mydomain/fullchain.pem"
postconf -e "smtpd_tls_key_file = /etc/letsencrypt/live/$mydomain/privkey.pem"
postconf -e "virtual_transport=dovecot"
postconf -e 'proxy_read_maps = $local_recipient_maps $mydestination $virtual_alias_maps $virtual_alias_domains $virtual_mailbox_maps $virtual_mailbox_domains $relay_recipient_maps $relay_domains $canonical_maps $sender_canonical_maps $recipient_canonical_maps $relocated_maps $transport_maps $mynetworks $virtual_mailbox_limit_maps'
