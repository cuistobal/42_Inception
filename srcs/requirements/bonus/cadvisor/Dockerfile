# Dockerfile pour cAdvisor
FROM debian:bullseye

# Installation de wget et des certificats CA pour télécharger le binaire (Debian)
RUN apt-get update \
	&& apt-get install -y --no-install-recommends wget ca-certificates \
	&& update-ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

# Téléchargement du binaire cAdvisor (version compatible)
# On le place dans /usr/bin pour qu'il soit accessible
RUN wget https://github.com/google/cadvisor/releases/download/v0.47.0/cadvisor-v0.47.0-linux-amd64 -O /usr/bin/cadvisor

# On donne les droits d'exécution
RUN chmod +x /usr/bin/cadvisor

# Port par défaut de cAdvisor
EXPOSE 8080

# Lancement de l'application
CMD ["/usr/bin/cadvisor", "-logtostderr"]
