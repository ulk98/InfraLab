#!/bin/bash

#Mise à jour
sudo apt update && sudo apt upgrade -y

#Installation de Docker et Docker-compose
sudo apt install docker.io docker-compose -y

#Démarrage et activation de docker
sudo systemctl start docker
sudo systemctl enable docker

#Création du réseau docker pour les conteneurs critiques de l'infrastructure
docker network create --driver bridge --subnet=172.40.0.0/24 infra_net

