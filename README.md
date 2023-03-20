This repo contains the scripts to configure mail server on postfix and dovecot

You need to run scripts in this sequence:
  - 0-configure-postfix.sh
  - configure-mysql.py
  - 1-configure-saslauth.sh
  - 2-configure-dovecot.sh 

You should specify vars in these scripts:
  user       # your mail admin user in mysql
  password   # password for mail admin user
  dbname     # name of mysql database where will be stored emails
  host       # localhost or 127.0.0.1
  vmailuser  # user on your mail server for handling 
  vmailgroup # group of vmailuser
  mydomain   # your domain with MX, PTR and TXT records
  
Do not change these vars if you did not change tables in mysql mail database
  querry_domain
  querry_forwardings
  querry_mailboxes
  querry_email 

Befor executing any script you should read the comments in the script

After executing all scripts you should add users to the mail database via phpMyAdmin (if it was configured on this server) or via mysql command line running these commands:
  - USE mail;
  - INSERT INTO domains (domain) VALUES ('yourdomain.domain'); 
  - INSERT INTO users(email,password) values('user@yourdomain.domain', md5('yourpassword'));
