#!/bin/bash

# Règles iptables pour autoriser le trafic sur les ports nécessaires

#Autorisation du trafic ICMP
iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
#Autorisation du trafic TCP et UDP sur tous les ports
iptables -A INPUT -p tcp --dport 1:65535 -j ACCEPT
iptables -A INPUT -p udp --dport 1:65535 -j ACCEPT
#Autorisation du trafic Loopback
iptables -A INPUT -i lo -j ACCEPT
#Autorisation des connexions établies et relatives
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#Démarrage des services
service apache 2 start
service mysql start
service ssh start
service nfs-kernel-server start
service vsftpd start
service smbd start


: <<'END_OF_COMMENT'

# Configurer et démarrer DVWA
if [ -d "/var/www/html/dvwa" ]; then
    echo "Configuration de DVWA..."
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS dvwa;"
    
    if [ -f "/var/www/html/dvwa/config/config.inc.php" ]; then
        # Importer les fichiers SQL de DVWA si disponibles
        if [ -f "/var/www/html/dvwa/database/create_mssql_db.sql" ]; then
            mysql -u root dvwa < /var/www/html/dvwa/database/create_mssql_db.sql
        else
            echo "Erreur: Fichier de base de donnée DVWA non trouvé."
        fi
    else
        echo "Erreur: Fichier de configuration DVWA non trouvé."
    fi
else
    echo "Erreur: Répertoire DVWA non trouvé."
fi

END_OF_COMMENT

# Boucle infinie pour que le conteneur reste actif
tail -f /dev/null

