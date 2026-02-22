#!/bin/sh

VM=${VM_NAME:-Inception_VM}

echo "Starting cleanup for VM: $VM..."

# 1. Nettoyage Docker (Seulement si la VM tourne)
# On regarde si "running" apparait dans le statut
if vagrant status | grep -q "running"; then
    echo "$VM is running. Cleaning Docker system..."
    # On ajoute "|| true" pour ne pas stopper le script si Docker n'est pas encore installé
    vagrant ssh -c "docker system prune -af --volumes" 2>/dev/null || true
else
    echo "zzz VM is not running or doesn't exist. Skipping Docker cleanup."
fi

# 2. Destruction propre via Vagrant
echo "Destroying Vagrant machine..."
vagrant destroy -f || true

# 3. Nettoyage des fichiers locaux de Vagrant
rm -rf .vagrant

# 4. (Optionnel mais recommandé) Nettoyage "Force Brute" VirtualBox
# Ça règle définitivement ton problème "A VirtualBox machine with the name... already exists"
# On vérifie si la commande VBoxManage existe sur le PC hôte
if command -v VBoxManage >/dev/null 2>&1; then
    # Si une VM avec ce nom existe encore dans VirtualBox
    if VBoxManage list vms | grep -q "\"$VM\""; then
        echo "Orphan VM found in VirtualBox registry. Force deleting..."
        VBoxManage unregistervm "$VM" --delete 2>/dev/null || true
    fi
fi

echo "fclean complete."
