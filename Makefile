NAME        = Inception_VM

# let's get ready to ruuuuumble
all: build up

# Cree la VM via Vagrant et copie le code a l interieur de cette derniere
build:
	@echo "Setting up VM..."
	@sh srcs/setup.sh

# Lance les containers dans la VM
up:
	@echo "Starting containers..."
	@vagrant ssh -c "cd /home/vagrant/Inception/srcs && docker compose up -d --build"

# Stop les containes
down:
	@echo "Stopping containers..."
	@vagrant ssh -c "cd /home/vagrant/Inception/srcs && docker compose down" 2>/dev/null || true

# Stop les containers et shut down la VM
clean: down
	@echo "Cleaning containers..."
	@vagrant ssh -c "cd /home/vagrant/Inception/srcs && docker compose down -v" 2>/dev/null || true

# Grand menage de Printemps
fclean:
	@sh srcs/fclean.sh

# Frero lance cette commande t en a pour 20 ans
re: fclean all

# Utilitaires
# Affichage des logs
logs:
	@vagrant ssh -c "cd /home/vagrant/Inception/srcs && docker compose logs -f"

# Affichage de l etat des containers
ps:
	@vagrant ssh -c "cd /home/vagrant/Inception/srcs && docker compose ps"

# Connexion ssh a la VM
ssh:
	@vagrant ssh

# Affichage des ports
ports:
	@vagrant ssh -c "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

.PHONY: all build up down clean fclean re logs ps ssh
