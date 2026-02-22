Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.hostname = "inception-vm"

  # Sync project directory from host to VM so builds run inside the VM
  # Allows `cd /home/Inception/srcs && docker compose ...` to work inside the VM
  # Use a fixed guest path instead of `$PWD` which can be empty in the Vagrantfile context
  config.vm.synced_folder ".", "/home/Inception", owner: "vagrant", group: "vagrant"
  
  # Forward guest 443 (nginx) to host 443 to access https://chrleroy.42.fr without a custom port.
  # Note: binding to host port 443 may require admin privileges on the host and will fail if
  # the host already has a service listening on port 443 (e.g. local nginx or Apache).
  config.vm.network "forwarded_port", guest: 443, host: 443, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 8080, host: 8080, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 8081, host: 8081, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 9443, host: 9443, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 22, host: 2222, host_ip: "127.0.0.1", id: "ssh"
  config.vm.network "forwarded_port", guest: 8082, host: 8082
  
  # Private network to access the VM from the host and the LAN.
  # This adds a second NIC with a fixed IP so you can use that IP
  # to test service access without port-forwarding or sudo on the host.
  config.vm.network "private_network", ip: "192.168.56.101"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "Inception_VM"
    vb.memory = "4096"
    vb.cpus = 2
end
  
  config.vm.provision "shell", inline: <<-SHELL
    echo "📦 Mise à jour du système..."
    apt-get update
    apt-get upgrade -y
    
    echo "📦 Installation des dépendances..."
    apt-get install -y ca-certificates curl gnupg lsb-release
    
    echo "🐳 Configuration de Docker..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    echo "🐳 Installation de Docker..."
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    usermod -aG docker vagrant
    
    echo "🛠️  Installation des outils..."
    apt-get install -y git make vim curl wget net-tools ftp
    
    echo "🌐 Configuration du domaine..."
    echo "127.0.0.1 chrleroy.42.fr" >> /etc/hosts
    
    echo "📁 Création des répertoires..."
    # Use /home/vagrant/data so it lines up with the VM user and the Compose HOST_DATA_PATH
    mkdir -p /home/vagrant/data/{wordpress,mariadb,portainer}
    chown -R vagrant:vagrant /home/vagrant/data
    # Ensure MariaDB files are owned by the mysql UID/GID used inside the container (usually 999)
    chown -R 999:999 /home/vagrant/data/mariadb || true
    
    echo "✅ Installation terminée !"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📌 VM prête pour Inception"
    echo "🔹 Connecte-toi avec : vagrant ssh"
    echo "🔹 Docker version : $(docker --version)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  SHELL
end
