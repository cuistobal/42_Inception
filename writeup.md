# General Docker commands

Basic commands to start/stop or restart a given container
```bash
docker start
docker stop
docker restart
```

These commands remove stopped && unreferenced containers. -a also includes 
unused containers
```bash
docker system prune
docker system prune -a
```

These commands are used to copy files from/to a container
```bash
docker cp <src> <container>:<dest>

docker cp dump.sql mariadb:/tmp/dump.sql
docker cp mariadb:/var/lib/mysql ./backup
```

Displays the current container running && their state. add -a to included 
stoped containers. you can get more insights by running docker inspect:
```bash
docker ps
docker ps -a
docker inspect <container>
```

Execute a command or run a shell inside a container using the following command.
-u && -p options are optional. Note that you'll be prompted for the password if
you don't provide it on the cli instruction:
```bash
docker exec -it <container> <cmd> -u <user> -p <password>
```


# About Redis:

Redis is an open source cache. Caching improves performance of web server by
storing a reference to recently used ressources. this way, they can be served
to the client without fetching from the server. Improves speed, reduces load

```bash
docker exec -it mariadb mysql -u root -p$ROOT_PASSWORD
```


# Connection to MariaDB
```bash
docker exec -it mariadb mysql -u root -p$ROOT_PASSWORD
```

# Showing all databases
```bash
MariaDB [(none)]> show databases;
```

# Select one database
```bash
MariaDB [(none)]> use XXX;
```

# Show db tables
```bash
MariaDB [XXX]> show tables;
```


# Adminer panel

A tool that makes db management easier && more User friendly than pure SQL as 
seen earlier.

System:MySql/MariaDB
Server:mariadb:3306
Username: $WP_USERNAME
Password: $WP_PASSWORD
Database: <empty for all dbs>

# Cadvisor

A tool to monitor hardware usage from your containers. i would have implemented
Vault if it wasn't such a burden (especially without proper SSL certificate
management)


