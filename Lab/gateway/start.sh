#!/bin/sh

# Activation du NAT (si nécessaire)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Règles iptables pour autoriser le routage entre les conteneurs
iptables -A FORWARD -s 172.50.0.0/24 -d 172.60.0.0/24 -j ACCEPT
iptables -A FORWARD -s 172.60.0.0/24 -d 172.50.0.0/24 -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

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

# Boucle infinie pour que le conteneur reste actif
tail -f /dev/null
