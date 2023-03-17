#!/usr/bin/python3

# you should execute this script with sudo privileges like "sudo ./configure-mysql.py"
# if you execute this script from the shell you should install mysql-connector-python
# call "pip install mysql-connector-python"

import mysql.connector


def main():
    root_user = 'root'
    password = 'userubuntu'
    localhost = 'localhost'
    db = 'mail'
    new_user = 'mail_admin'
    new_user_pass = 'mail_admin_password'

    create_database(root_user, password, localhost, db)
    create_user(root_user, password, localhost, db, new_user, new_user_pass)
    create_domain_tables(root_user, password, localhost, db)


def create_database(root_user, password, host, database_name):
    try:
        with mysql.connector.connect(
            user=root_user,
            password=password,
            host=host,
            auth_plugin='mysql_native_password'
        ) as conn:
            with conn.cursor() as cur:
                cur.execute('CREATE DATABASE IF NOT EXISTS %s;' % database_name)
    except mysql.connector.Error as err:
        print('Database Error', err)


def create_user(root_user, password, host, database_name, new_user, new_user_password):
    try:
        with mysql.connector.connect(
            user=root_user,
            password=password,
            host=host,
            auth_plugin='mysql_native_password'
        ) as conn:
            with conn.cursor() as cur:
                cur.execute('USE %s;' % database_name)
                cur.execute("CREATE USER IF NOT EXISTS '%s'@'localhost' IDENTIFIED BY '%s';"
                            % (new_user, new_user_password))
                cur.execute("GRANT SELECT, INSERT, UPDATE, DELETE ON %s.* TO '%s'@'localhost';"
                            % (database_name, new_user))
                cur.execute('FLUSH PRIVILEGES;')
    except mysql.connector.Error as err:
        print('Database Error', err)


def create_domain_tables(root_user, password, host, database_name):
    try:
        with mysql.connector.connect(
            user=root_user,
            password=password,
            host=host,
            auth_plugin='mysql_native_password'
        ) as conn:
            with conn.cursor() as cur:
                cur.execute('USE %s;' % database_name)
                cur.execute('''CREATE TABLE IF NOT EXISTS domains (
                               domain varchar(50) NOT NULL, PRIMARY KEY (domain));
                            ''')
                cur.execute('''CREATE TABLE IF NOT EXISTS users (
                                email varchar(80) NOT NULL, 
                                password varchar(128) NOT NULL, PRIMARY KEY (email));
                            ''')
                cur.execute('''CREATE TABLE IF NOT EXISTS forwardings (
                                source varchar(80) NOT NULL,
                                destination TEXT NOT NULL, PRIMARY KEY (source));
                            ''')
    except mysql.connector.Error as err:
        print('Database Error', err)


if __name__ == '__main__':
    main()
