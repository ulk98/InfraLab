#!/bin/bash

# Nom de l'utilisateur qui doit avoir accès au script sans mot de passe
USERNAME="etudiant"

# Chemin du script à exécuter avec sudo sans mot de passe
SCRIPT_PATH="./Lab/start_lab.sh"

# Fichier temporaire pour modification du sudoers
SUDOERS_TEMP="/tmp/$USERNAME-sudoers"

# Vérifier si le script existe
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Le script spécifié n'existe pas : $SCRIPT_PATH"
    exit 1
fi

# Vérifier si l'utilisateur existe
if id "$USERNAME" &>/dev/null; then
    echo "Configuration de sudo pour l'utilisateur $USERNAME..."
else
    echo "L'utilisateur $USERNAME n'existe pas. Veuillez vérifier."
    exit 1
fi

# Ajouter la règle sudo pour cet utilisateur sans mot de passe
echo "$USERNAME ALL=(ALL) NOPASSWD: $SCRIPT_PATH" > $SUDOERS_TEMP

# Appliquer le fichier sudoers temporaire dans le système
sudo visudo -cf $SUDOERS_TEMP
if [ $? -eq 0 ]; then
    sudo cp $SUDOERS_TEMP /etc/sudoers.d/$USERNAME
    sudo chmod 440 /etc/sudoers.d/$USERNAME
    echo "La règle sudo a été appliquée avec succès pour $USERNAME sur le script $SCRIPT_PATH."
else
    echo "Erreur dans la validation du fichier sudoers temporaire. Aucune modification n'a été apportée."
    exit 1
fi

# Nettoyage du fichier temporaire
rm -f $SUDOERS_TEMP

echo "Script terminé."
