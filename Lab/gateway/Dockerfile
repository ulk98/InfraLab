FROM alpine:latest

# Installation des paquets nécessaires
RUN apk update && apk upgrade
RUN apk add --no-cache iptables iproute2

# Activation du routage IP
RUN echo net.ipv4.ip_forward=1 | tee -a /etc/sysctl.conf && sysctl -p

# Exposer les ports pour les services vulnérables
EXPOSE 21 22 23 25 53 80 111 137 138 139 443 445 3306 2049 3000 3128 3389 8080

# Script de démarrage pour configurer le routage et les règles iptables
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Définir le script de démarrage comme le point d'entrée de l'image
ENTRYPOINT ["/usr/local/bin/start.sh"]
