#!/bin/bash

#Déploiement du lab
echo "Déploiement du Lab..."
./deploy_lab.sh

#Démarrage du Lab
echo "Lancement du Lab.."
docker-compose up -d

#Démarrage des services de la cibles
#: <<'END_OF_COMMENT
# Récupération de la liste des conteneurs dont le nom contient le mot "cible"
containers=$(docker ps --filter "name=cible" --format "{{.Names}}")

# Vérification que la liste des conteneur n'est pas vible
if [ -z "$containers" ]; then
    exit 1
fi

# Démarrage des services dans chaque conteneur cible
for container in $containers; do
    echo "Exécution de la commande dans le conteneur: $container"
    docker exec -it "$container" ./usr/local/bin/launch_services.sh
done
#END_OF_COMMENT

echo "Votre Lab est prêt..."
