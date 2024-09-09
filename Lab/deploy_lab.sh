#!/bin/bash

fichier="docker-compose.yml"

read -p "Nombre de conteneurs cibles: " num_targets
read -p "Nombre de conteneurs attaquants: " num_attackers
read -p "Voulez-vous inclure des conteneurs de défense dans votre lab? (oui/non): " include_defense
read -p "Voulez-vous simuler un même réseau pour les conteneurs d'attaque et de défense? (oui/non): " single_network

#Suppression du fichier docker-compose.yml existant
if [ -f "$fichier" ]; then
    rm "$fichier"
fi

#Début du fichier docker-compose.yml
echo "version: '3'" > "$fichier"
echo "services:" >> "$fichier"

#Configuration des cibles vulnérables
for i in $(seq 1 $num_targets); do
  echo "  cible_$i:" >> "$fichier"
  echo "    image: test/vuln-ubuntu" >> "$fichier"
  echo "    cap_add:" >> "$fichier"
  echo "      - NET_ADMIN" >> "$fichier"
  echo "      - NET_RAW" >> "$fichier"
  echo "    networks:" >> "$fichier"
  echo "      lan_net:" >> "$fichier"
  echo "        ipv4_address: 172.50.0.$((i + 1))" >> "$fichier"
  if [ "$single_network" == "oui" ]; then
    echo "    command: sh -c 'tail -f /dev/null'" >> "$fichier"
  else
    echo "    command: sh -c 'ip route replace default via 172.50.0.250 && tail -f /dev/null'" >> "$fichier"
  fi
done

# Configuration des attaquants
for i in $(seq 1 $num_attackers); do
  echo "  attacker_$i:" >> "$fichier"
  echo "    image: test/kali_attack" >> "$fichier"
  echo "    cap_add:" >> "$fichier"
  echo "      - NET_ADMIN" >> "$fichier"
  echo "      - NET_RAW" >> "$fichier"
  if [ "$single_network" == "oui" ]; then
    echo "    networks:" >> "$fichier"
    echo "      lan_net:" >> "$fichier"
    echo "        ipv4_address: 172.50.0.$((200 + i))" >> "$fichier"
    echo "    command: sh -c 'tail -f /dev/null'" >> "$fichier"
  else
    echo "    networks:" >> "$fichier"
    echo "      wan_net:" >> "$fichier"
    echo "        ipv4_address: 172.60.0.$((i + 1))" >> "$fichier"
    echo "    command: sh -c 'ip route replace default via 172.60.0.250 && tail -f /dev/null'" >> "$fichier"
  fi
done

# Ajout des conteneurs de défense
if [ "$include_defense" == "oui" ]; then
  echo "  wazuh:" >> "$fichier"
  echo "    image: wazuh/wazuh:4.2.7" >> "$fichier"
  echo "    hostname: wazuh" >> "$fichier"
  echo "    ports:" >> "$fichier"
  echo "      - 1514:1514/udp" >> "$fichier"
  echo "      - 1515:1515" >> "$fichier"
  echo "      - 514:514/udp" >> "$fichier"
  echo "      - 55000:55000" >> "$fichier"
  echo "      - 55000:55000/udp" >> "$fichier"
  echo "    networks:" >> "$fichier"
  echo "      lan_net:" >> "$fichier"
  echo "        ipv4_address: 172.50.0.196" >> "$fichier"

  echo "  wazuh-kibana:" >> "$fichier"
  echo "    image: wazuh/wazuh-kibana:4.2.7" >> "$fichier"
  echo "    networks:" >> "$fichier"
  echo "      lan_net:" >> "$fichier"
  echo "        ipv4_address: 172.50.0.197" >> "$fichier"
  echo "    ports:" >> "$fichier"
  echo "      - 5601:5601" >> "$fichier"
  echo "    environment:" >> "$fichier"
  echo "      ELASTICSEARCH_HOSTS: 'http://elasticsearch:9200'" >> "$fichier"

  echo "  elasticsearch:" >> "$fichier"
  echo "    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.1" >> "$fichier"
  echo "    networks:" >> "$fichier"
  echo "      lan_net:" >> "$fichier"
  echo "        ipv4_address: 172.50.0.198" >> "$fichier"
  echo "    environment:" >> "$fichier"
  echo "      - discovery.type=single-node" >> "$fichier"
  echo "      - ES_JAVA_OPTS=-Xms1g -Xmx1g" >> "$fichier"
  echo "    ports:" >> "$fichier"
  echo "      - 9200:9200" >> "$fichier"

  echo "  suricata:" >> "$fichier"
  echo "    image: jasonish/suricata:latest" >> "$fichier"
  echo "    cap_add:" >> "$fichier"
  echo "      - NET_RAW" >> "$fichier"
  echo "      - NET_ADMIN" >> "$fichier"
  echo "    networks:" >> "$fichier"
  echo "      lan_net:" >> "$fichier"
  echo "        ipv4_address: 172.50.0.199" >> "$fichier"
  echo "    command: ['-i', 'eth0']" >> "$fichier" 
  echo "    volumes:" >> "$fichier"
  echo "      - ./suricata:/etc/suricata" >> "$fichier"
  echo "    ports:" >> "$fichier"
  echo "      - 3000:3000" >> "$fichier"

fi

# Configuration de la passerelle (si l'utilisateur ne veut pas un réseau unique
if [ "$single_network" == "non" ]; then
  echo "  gateway:" >> "$fichier"
  echo "    image: test/gateway" >> "$fichier"
  echo "    networks:" >> "$fichier"
  echo "      lan_net:" >> "$fichier"
  echo "        ipv4_address: 172.50.0.250" >> "$fichier"
  echo "      wan_net:" >> "$fichier"
  echo "        ipv4_address: 172.60.0.250" >> "$fichier"
  echo "    privileged: true" >> "$fichier"
  echo "    cap_add:" >> "$fichier"
  echo "      - NET_ADMIN" >> "$fichier"
  echo "      - NET_RAW" >> "$fichier"
fi

# Configuration des réseaux
echo "networks:" >> "$fichier"
echo "  lan_net:" >> "$fichier"
echo "    driver: bridge" >> "$fichier"
echo "    ipam:" >> "$fichier"
echo "      config:" >> "$fichier"
echo "       - subnet: 172.50.0.0/24" >> "$fichier"
if [ "$single_network" == "non" ]; then
  echo "  wan_net:" >> "$fichier"
  echo "    driver: bridge" >> "$fichier"
  echo "    ipam:" >> "$fichier"
  echo "      config:" >> "$fichier"
  echo "        - subnet: 172.60.0.0/24" >> "$fichier"
fi

echo "Fichier de configuration du lab généré : $fichier"

chmod +x "$fichier"
