#!/bin/bash

# Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# Installation des dépendances nécessaires
sudo apt install -y build-essential libcairo2-dev libjpeg-turbo8-dev libpng-dev \
libtool-bin libossp-uuid-dev libvncserver-dev libssl-dev libpango1.0-dev \
libssh2-1-dev libtelnet-dev libvte-2.91-dev libpulse-dev libvorbis-dev \
libwebp-dev libmysql-java libmariadb-java libfreerdp-dev libavcodec-dev \
libavformat-dev libswscale-dev libogg-dev libavutil-dev libswscale-dev \
freerdp2-dev freerdp2-x11 libvorbis-dev tomcat9 tomcat9-admin tomcat9-common \
mysql-server mysql-client slapd ldap-utils nginx certbot python3-certbot-nginx \
auditd audispd-plugins

# Téléchargement et installation de Guacamole Server
wget https://apache.org/dyn/closer.lua/guacamole/1.4.0/source/guacamole-server-1.4.0.tar.gz
tar -xzf guacamole-server-1.4.0.tar.gz
cd guacamole-server-1.4.0
./configure --with-init-dir=/etc/init.d
make
sudo make install
sudo ldconfig
sudo systemctl start guacd
sudo systemctl enable guacd

# Installation de Guacamole Client (Tomcat et fichier WAR)
wget https://apache.org/dyn/closer.lua/guacamole/1.4.0/binary/guacamole-1.4.0.war
sudo mv guacamole-1.4.0.war /var/lib/tomcat9/webapps/guacamole.war
sudo systemctl restart tomcat9

# Configuration de MySQL pour Guacamole
sudo mysql -e "CREATE DATABASE guac_db;"
sudo mysql -e "CREATE USER 'guac_user'@'localhost' IDENTIFIED BY 'guac_password';"
sudo mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE ON guac_db.* TO 'guac_user'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Initialisation de la base de données Guacamole
wget https://apache.org/dyn/closer.lua/guacamole/1.4.0/binary/guacamole-auth-jdbc-1.4.0.tar.gz
tar -xzf guacamole-auth-jdbc-1.4.0.tar.gz
sudo mv guacamole-auth-jdbc-1.4.0/mysql/ /etc/guacamole/
sudo mysql guac_db < /etc/guacamole/mysql/schema/001-create-schema.sql

# Configuration de Guacamole pour utiliser MySQL
sudo mkdir /etc/guacamole
cat <<EOT | sudo tee /etc/guacamole/guacamole.properties
mysql-hostname: localhost
mysql-port: 3306
mysql-database: guac_db
mysql-username: guac_user
mysql-password: guac_password
EOT

# Ajout du driver JDBC dans Tomcat
sudo ln -s /etc/guacamole/mysql/guacamole-auth-jdbc-mysql-1.4.0.jar /var/lib/tomcat9/lib/
sudo systemctl restart tomcat9

# Configuration LDAP
sudo dpkg-reconfigure slapd

# Configuration de Guacamole pour LDAP
cat <<EOT | sudo tee -a /etc/guacamole/guacamole.properties
ldap-hostname: localhost
ldap-port: 389
ldap-user-base-dn: ou=users,dc=infra_lab,dc=com
ldap-username-attribute: uid
ldap-search-bind-dn: cn=admin,dc=infra_lab,dc=com
ldap-search-bind-password: admin_password
EOT

# Ajouter un utilisateur LDAP
cat <<EOT | sudo ldapadd -x -D cn=admin,dc=infra_lab,dc=com -w admin_password
dn: ou=users,dc=infra_lab,dc=com
objectClass: organizationalUnit
ou: users

dn: uid=testuser,ou=users,dc=infra_lab,dc=com
objectClass: inetOrgPerson
sn: User
givenName: Test
cn: Test User
uid: testuser
userPassword: user_password
EOT

# Installation et configuration de Nginx
sudo apt install -y nginx
cat <<EOT | sudo tee /etc/nginx/sites-available/guacamole
server {
    listen 80;
    server_name 194.164.79.129;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name 194.164.79.129;

    ssl_certificate ./nginx/ssl/nginx.crt;
    ssl_certificate_key ./nginx/ssl/nginx.key;

    location / {
        proxy_pass http://localhost:8080/guacamole/;
        proxy_buffering off;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOT

# Activation du site Nginx et redémarrage
sudo ln -s /etc/nginx/sites-available/guacamole /etc/nginx/sites-enabled/
sudo systemctl restart nginx

# Installation de Falco
curl -s https://s3.amazonaws.com/download.draios.com/stable/install-falco | sudo bash
sudo apt-get install -y falco
sudo systemctl start falco
sudo systemctl enable falco

# Configuration de règles d'Auditd
sudo systemctl start auditd
sudo systemctl enable auditd
cat <<EOT | sudo tee /etc/audit/audit.rules
-w /etc/passwd -p wa -k passwd_changes
-w /etc/guacamole/ -p wa -k guacamole_conf
EOT

# Redémarrage des services
sudo systemctl restart guacd tomcat9 nginx auditd falco
