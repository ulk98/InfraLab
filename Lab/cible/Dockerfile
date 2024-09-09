# Utiliser une image Ubuntu comme base
FROM ubuntu:20.04

# Définir l'environnement pour les installations non-interactives
ENV DEBIAN_FRONTEND=noninteractive

# Mettre à jour les paquets et installer des dépendances de base
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apache2 \
    iptables \
    iproute2 \
    net-tools \
    iputils-ping \
    php \
    mysql-server \
    php-mysql \
    openssh-server \
    wget \
    curl \
    unzip \
    git \
    nodejs \
    npm \
    samba \
    netcat \
    vsftpd \
    nfs-kernel-server && \
    rm -rf /var/lib/apt/lists/*


# Installer et configurer OWASP Juice Shop
RUN wget https://github.com/juice-shop/juice-shop/releases/download/v13.2.0/juice-shop-13.2.0_node16_linux_x64.tgz -O /tmp/juice-shop.tgz && \
    mkdir -p /var/www/html/juice-shop && \
    tar -xvzf /tmp/juice-shop.tgz -C /var/www/html/juice-shop && \
    rm /tmp/juice-shop.tgz

# Installer et configurer DVWA
RUN mkdir /var/www/html/dvwa && \
    cd /var/www/html/dvwa && \
    git clone https://github.com/digininja/DVWA.git . && \
    cp /var/www/html/dvwa/config/config.inc.php.dist /var/www/html/dvwa/config/config.inc.php && \
    chown -R www-data:www-data /var/www/html/dvwa &&\
    sed -i "s/$_DVWA\[ 'db_password' \] = '';/$_DVWA\[ 'db_password' \] = 'p@ssw0rd';/g" /var/www/html/dvwa/config/config.inc.php

# Configurer Apache pour servir DVWA et Juice Shop
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    a2enmod rewrite && \
    a2enmod php7.4 && \
    sed -i "s/\/var\/www\/html/\/var\/www\/html\/dvwa/g" /etc/apache2/sites-available/000-default.conf &&\
    echo "Alias /dvwa /var/www/html/dvwa" >> /etc/apache2/sites-available/000-default.conf

# Ajouter des vulnérabilités applicatives (Injection SQL et XSS)
RUN echo '<?php \
$conn = new mysqli("localhost", "root", "", "dvwa"); \
if ($conn->connect_error) { die("Connection failed: " . $conn->connect_error); } \
$user_input = $_GET["id"]; \
$sql = "SELECT * FROM users WHERE id = " . $user_input; \
$result = $conn->query($sql); \
if ($result->num_rows > 0) { while($row = $result->fetch_assoc()) { echo "User: " . $row["username"]. "<br>"; } } else { echo "0 results"; } \
$conn->close(); \
?>' > /var/www/html/dvwa/sql_vulnerable.php

RUN echo '<html><body><form action="xss.php" method="GET"> \
Search: <input type="text" name="query"> \
<input type="submit"> \
</form> \
<?php echo "Results: " . $_GET["query"]; ?> \
</body></html>' > /var/www/html/dvwa/xss.php

# Ajouter des fichiers avec des permissions incorrectes
RUN echo "Mot de passe: secret_password" > /var/www/html/passwords.txt && \
    chmod 777 /var/www/html/passwords.txt

# Simuler Metasploitable3 : installation de paquets vulnérables
RUN mkdir -p /var/ftp && \
    echo "Bienvenue sur Metasploitable3 FTP!" > /var/ftp/welcome.msg && \
    mkdir -p /home/export && \
    echo "/home/export *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports && \
    service nfs-kernel-server restart

# Configurer SSH avec des mauvaises pratiques de sécurité
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'root:root' | chpasswd

# Configurer les volumes
VOLUME ["/var/ftp", "/home/export", "/mnt/nfs"]

# Exposer les ports pour les services vulnérables
EXPOSE 21 22 23 25 53 80 111 137 138 139 443 445 3306 2049 3000 3128 3389 8080

# Commande de démarrage pour lancer tous les services (JSON Syntaxe)
CMD ["bash", "-c", "service apache2 start && service mysql start && service ssh start && /var/www/html/juice-shop/start.sh && bash"]

# Script de démarrage pour configurer configurer les règle iptables afin d'autoriser le trafic sur le conteneur

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

COPY launch_services.sh /usr/local/bin/launch_services.sh
RUN chmod +x /usr/local/bin/launch_services.sh


# Définir le script comme le point d'entrée de l'image
ENTRYPOINT ["/usr/local/bin/start.sh"]
