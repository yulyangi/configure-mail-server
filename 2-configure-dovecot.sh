#!/bin/bash

# declare the vars
vmailuser='vmail'
vmailgroup='vmail'
mydomain='binbash.site'
user='mail_admin'
password='mail_admin_password'
dbname='mail'
host='127.0.0.1'

# add some lines to the /etc/postfix/master.cf
if ! grep $vmailuser:$vmailgroup /etc/postfix/master.cf > /dev/null; then
cat<<END>> /etc/postfix/master.cf
dovecot   unix  -       n       n       -       -       pipe
    flags=DRhu user=$vmailuser:$vmailgroup argv=/usr/lib/dovecot/deliver -d \${recipient}
END
fi

# add smtps protocol
sed -i 's|^#smtps.*|smtps     inet  n       -       y       -       -       smtpd|' /etc/postfix/master.cf

# remove all and add some text
cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.backup

cat<<END> /etc/dovecot/dovecot.conf
log_timestamp = "%Y-%m-%d %H:%M:%S "
mail_location = maildir:/var/$vmailuser/%d/%n/Maildir
managesieve_notify_capability = mailto
managesieve_sieve_capability = fileinto reject envelope encoded-character vacation subaddress comparator-i;ascii-numeric relational regex imap4flags copy include variables body enotify environment mailbox date
namespace {
  inbox = yes
  location = 
  prefix = INBOX.
  separator = .
  type = private
}
passdb {
  args = /etc/dovecot/dovecot-sql.conf
  driver = sql
}
protocols = imap pop3

service auth {
  unix_listener /var/spool/postfix/private/auth {
    group = postfix
    mode = 0660
    user = postfix
  }
  unix_listener auth-master {
    mode = 0600
    user = $vmailuser
  }
  user = root
}

userdb {
  args = uid=5000 gid=5000 home=/var/$vmailuser/%d/%n allow_all_users=yes
  driver = static
}

protocol lda {
  auth_socket_path = /var/run/dovecot/auth-master
  log_path = /var/$vmailuser/dovecot-deliver.log
  mail_plugins = sieve
  postmaster_address = postmaster@example.com
}

protocol pop3 {
  pop3_uidl_format = %08Xu%08Xv
}

service stats {
  unix_listener stats-reader {
    user = dovecot
    group = $vmailgroup
    mode = 0660
  }
  unix_listener stats-writer {
    user = dovecot
    group = $vmailgroup
    mode = 0660
  }
}

ssl = yes
ssl_cert = </etc/letsencrypt/live/$mydomain/fullchain.pem
ssl_key = </etc/letsencrypt/live/$mydomain/privkey.pem
END

# create new file
cat<<END> /etc/dovecot/dovecot-sql.conf
driver = mysql
connect = host=$host dbname=$dbname user=$user password=$password
default_pass_scheme = PLAIN-MD5
password_query = SELECT email as user, password FROM users WHERE email='%u';
END

# restart dovecot
systemctl restart dovecot
