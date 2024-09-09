#!/bin/bash

echo "Suppression du Lab..."

#Suppression du Lab
docker-compose down

echo "Suppression du Lab confirmé..."

#Suppression du fichier docker-compose.yml
rm docker-compose.yml

echo "Fichier de configuration du Lab supprimé avec succès..."
