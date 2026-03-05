FROM debian:bookworm

# Installation de curl et tar. libc6-compat n'est pas nécessaire sur Debian car c'est la libc standard.
# ca-certificates est souvent requis pour curl en HTTPS.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    tar \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Téléchargement de la version 2.21.5
RUN curl -L https://github.com/portainer/portainer/releases/download/2.21.5/portainer-2.21.5-linux-amd64.tar.gz \
    -o portainer.tar.gz && \
    tar xvpfz portainer.tar.gz && \
    rm portainer.tar.gz && \
    mv portainer /usr/local/bin/

# Nettoyage pour garder l'image légère (bonnes pratiques 42)
# Sur Debian, on évite parfois de désinstaller curl/tar si l'image est utilisée pour du debug, 
# mais pour respecter la logique précédente :
RUN apt-get purge -y curl tar && apt-get autoremove -y

# Portainer a besoin d'un dossier data pour# filepath: /home/chrleroy/Code/Github/Inception/srcs/requirements/bonus/portainer/Dockerfile
FROM debian:bookworm

# Installation de curl et tar. libc6-compat n'est pas nécessaire sur Debian car c'est la libc standard.
# ca-certificates est souvent requis pour curl en HTTPS.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    tar \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Téléchargement de la version 2.21.5
RUN curl -L https://github.com/portainer/portainer/releases/download/2.21.5/portainer-2.21.5-linux-amd64.tar.gz \
    -o portainer.tar.gz && \
    tar xvpfz portainer.tar.gz && \
    rm portainer.tar.gz && \
    mv portainer /usr/local/bin/

# Nettoyage pour garder l'image légère (bonnes pratiques 42)
# Sur Debian, on évite parfois de désinstaller curl/tar si l'image est utilisée pour du debug, 
# mais pour respecter la logique précédente :
# RUN apt-get purge -y curl tar && apt-get autoremove -y

# Portainer a besoin d'un dossier data pour persister ses données
WORKDIR /usr/local/bin/portainer

EXPOSE 9443

#Lancement
CMD ["./portainer", "--bind=:9443", "--tunnel-port=8000", "--data=/data"]