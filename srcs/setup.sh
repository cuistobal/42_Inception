#!/bin/sh
# On garde -e pour quitter en cas d'erreur, -u pour les variables non définies
set -eu

echo "$0: Starting VM named ${VM_NAME:-Inception_VM}..."

# 1. On lance la VM. Si elle tourne déjà, vagrant up ne fera rien (c'est ok).
# La variable VM_NAME sera lue automatiquement par le Vagrantfile ici.
vagrant up

# 2. On prépare les dossiers
vagrant ssh -c "sudo mkdir -p /home/vagrant/data/wordpress /home/vagrant/data/mariadb /home/vagrant/data/portainer && sudo chown -R vagrant:vagrant /home/vagrant/data || true"
echo "$0 Checking VM for sources..."

# 3. Logique de build
if vagrant ssh -c "test -d /home/vagrant/Inception/srcs" >/dev/null 1>&1; then
    echo "$0 Sources found in VM — building inside VM..."
    vagrant ssh -c "cd /home/vagrant/Inception/srcs && docker compose build"
else
    echo "$0 Sources not found in VM — uploading srcs to VM..."
    # Upload into the vagrant user's home (writable) instead of /home/Inception
    # vagrant upload écrase souvent, c'est bien pour la mise à jour
    vagrant upload srcs /home/vagrant/Inception/srcs
    echo "$0 Uploaded. Building inside VM..."
    vagrant ssh -c "cd /home/vagrant/Inception/srcs && docker compose build"
fi

# Ensure VM uses latest synced sources (if present under /home/Inception) so docker-compose inside
# /home/vagrant/Inception/srcs sees the updated files.
echo "$0: Syncing sources into VM if present..."
vagrant ssh -c "if [ -d /home/Inception/srcs ]; then sudo rm -rf /home/vagrant/Inception/srcs && sudo cp -a /home/Inception/srcs /home/vagrant/Inception && sudo chown -R vagrant:vagrant /home/vagrant/Inception/srcs || true; fi"

# Migrate MariaDB data into a Docker-managed volume to avoid host FS permission issues
# Only run when a host bind-data directory exists and the managed volume does not yet exist.
echo "$0: Checking MariaDB data migration..."
vagrant ssh -c "if [ -d /home/vagrant/data/mariadb ] && ! docker volume ls --format '{{.Name}}' | grep -q 'mariadb_data_local'; then
    echo '  Found host MariaDB data and no docker-managed volume; migrating to mariadb_data_local...'
    docker volume create mariadb_data_local >/dev/null
    echo '  Copying data into volume using debian:bookworm (no Alpine)'
    docker run --rm -v mariadb_data_local:/var/lib/mysql -v /home/vagrant/data/mariadb:/from debian:bookworm sh -c 'cp -a /from/. /var/lib/mysql && chown -R 999:999 /var/lib/mysql'
    echo '  Migration complete.'
else
    echo '  Migration not required.'
fi"

echo "$0 Done."