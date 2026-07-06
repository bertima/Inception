This project has been created as part of the 42 curriculum by bertrmar.

# __Table of Contents__

- [Overview](#overview)
- [Prerequisites and Environment Setup](#prerequisites-and-environment-setup)
  - [System Requirements](#system-requirements)
  - [Install Docker](#1-install-docker)
  - [Add Docker's GPG Key](#2-add-dockers-official-gpg-key)
  - [Add Docker's Repository](#3-add-dockers-official-repository)
  - [Install Docker Engine](#4-install-docker-engine--all-plugins)
  - [Verify the Installation](#5-verify-the-installation)
  - [Add User to Docker Group](#6-add-your-user-to-the-docker-group)
  - [Clone and Set Up Repository](#7-clone-and-set-up-repository)
  - [Set Up Environment Variables](#8-set-up-environment-variables)
  - [Start the Infrastructure](#9-start-the-infrastructure)
- [Configuration Files](#configuration-files)
  - [Docker Compose Configuration](#docker-compose-configuration)
  - [Makefile Structure and Automation](#makefile-structure-and-automation)
- [Building the Project](#building-the-project)
- [Docker Compose Management](#docker-compose-management)
- [Container Management](#container-management)
- [Volume Management](#volume-management)
- [Network Configuration](#network-configuration)
- [Service Details](#service-details)
  - [NGINX](#nginx-service)
  - [WordPress](#wordpress-service)
  - [MariaDB](#mariadb-service)
- [Debugging](#debugging)
- [Security Considerations](#security-considerations)
- [Data Storage and Persistence](#data-storage-and-persistence)
- [Useful Commands Reference](#useful-commands-reference)

## <u>__HOW DOCKER WORKS__</u>

find latest stable version 
alpine lts (in browser)
alpine less huge than debian

Namespaces : isolation des ressources (réseau, PID, utilisateurs…)
Cgroups : limitation des ressources (CPU, mémoire, I/O) (control groupe)
Capabilities : contrôle des privilèges (granularité fine des droits root)

install docker :
sudo apt install docker.io : version for linux
pour docker officiel : curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh (install docker compose + key)
add in group docker : sudo usermod -aG docker $USER
reboot

https://dyma.fr/blogAlthough it cannot guarantee error-free performance, as the behavior of an application ultimately depends on many factors beyond the image itself, using Docker can reduce the likelihood of unexpected errors.Although it cannot guarantee error-free performance, as the behavior of an application ultimately depends on many factors beyond the image itself, using Docker can reduce the likelihood of unexpected errors.

![image](https://geekflare.com/fr/wp-content/uploads/sites/26/2019/09/traditional-vs-new-gen.png)

## <u>__OTHER__</u>

files yaml ou yml for docker compose : easy for interpretation for many languages

Every Docker package is signed with a private key. Your system needs the corresponding public key to verify this signature. We could find this in /etc/apt/keyrings/.


container engine

Sur Linux : vous installez Docker Engine (daemon + CLI), c'est tout.

Sur macOS/Windows : vous installez Docker Desktop = application + VM + intégrations IDE + Kubernetes optionnel.

CRI = container runtime interface  
blob = Binary Large Object   

|Terme|Exemples|Role|
|----|----|----|
|Engine (moteur)|Docker, Podman|Build + run + UX complète  
|Runtime|containerd, CRI-O|Exécution uniquement, orienté CRI/Kubernetes|
|Build tools|BuildKit, Buildah, Kaniko|Construction d'images (voir guide build)| 
|System containers|LXC, Incus|OS complet dans un conteneur (logique « VM légère »)

PID1 doesn't received signal ctrl + C (SIGINT) or docker stop (SIGTERM) by default

## <u>__VOLUME__</u>
Persistante stores for containers


### *__DOCKER VOLUME__*

Persistante stores for containers  
Completely manage by docker  
easier to migrate and back up  
Work on windows and linux  
Manage with CLI or docker API
More safely share among multiple containers  
Hight perf I\O
Survive to containers

Not access files from the host  


### *__BIND MOUNT__*




## <u>__DOCKER FILE__</u>

Say how image could be mount  
Create layer in app image for each instruction, this layer are stack in cache like this the process is fast (only modifying layer are rebuild) and lightweight (layer could be share between several images)  
For optimasation let your instruction than never change on top and the other at the bottom

Images = couches empilées : chaque instruction FROM, RUN, COPY, ADD crée une nouvelle layer stockée comme un blob tar
Content-Addressable Storage : les couches sont identifiées par leur hash SHA256, permettant la déduplication automatique
Union Filesystem (OverlayFS) : superpose les couches read-only et utilise le Copy-on-Write pour les modifications
Immutabilité : une fois créée, une couche ne change jamais — c'est ce qui permet le cache et la déduplication
manifest.json : décrit la composition complète de l'image (config, layers, tags)
Ordre des instructions : crucial pour exploiter le cache — dépendances stables en haut, code en bas
Images minimales : préférez distroless ou Chainguard pour la sécurité (pas de shell, pas de CVE)

|Terme|Utilite|
|----|----|
|FROM|Permet de choisir l'image de base pour creer la notre|
|LABEL|Creer un alias sous forme cle=value|
|ONBUILD|Definit des instruction lors de l'execution de cette image pour creer une nouvelle image|
|ARG|Definit des variable qui peuvent etre transmise lors de la construction de l'image (seul instruction possible avant FROM)|
|ENV|Definir variable d'environnement qui seront utiliser dans RUN (disponible au moment de l'execution de l'image)|
|WORKDIR|Definit le workdirectory pour le reste des instructions qui suivent (si pas la = creer)|
|COPY|Permet d'intergrer des fichier ou dossier au systeme de fichier de l'image| 
|ADD|Meme utilite que COPY mais peux ajouter une archive ou une URL|
|RUN|lance des commande lors de la construction de l'image (chaque RUN = nouvelle couche du coup essayer de grouper)|
|CMD|Definit les commande a executer lors du lancement de l'image|
|ENTRYPOINT|Meme fonction que CMD mais contrairement a CMD les commandes ENtRYPOINT ne peuvent pas etre modifier|
|USER|Definit le user ou/et eventuellement le groupe de user pour le reste des commandes RUN + execution de l'image du conteneur|
|VOLUME|Creer un point de montage avec le param specifier, Stocker des donnees persistante meme si conteneur arreter ou supprimer|
|EXPOSE|Dit sur quelle port le conteneur ecoute (presistion possible TCP ou UDP mais TCP par default)|
|HEALTHCHECK|Definit commande qui s'execut tout les x pour verifier si le conteneur est ok sinon "non sain"|
|STOPSIGNAL|Definit signal envoyer au conteneur lorsqu'il s'arrete|
|SHELL|Dit quelle terminal lancer pour executer les commandent|  

|Concept|Define|
|--|--|
|Image|Modèle immuable (read-only) composé de layers|
|Conteneur|Processus isolé + layer R/W (éphémère par défaut)|
|docker-run|Crée puis démarre un conteneur (create → start)|
|State|created → running ↔ paused → exited → removed|
|Daemon|dockerd orchestre via API ; le client docker envoie des requêtes|
|Layers|Chaque instruction Dockerfile = une couche partagée et cachée|

### TSL

Transport layer security, modern version of SSL. Garanty security between app web and server for privacy data. This is garanty if you are in HTTPS if the browser say than the site doesn't have a good version of this one, it possibly dangerouse.

# __COMMAND__

## <u>__COMMAND DOCKER__</u>

### *__IMAGE MANAGE__*
```bash
docker build -t <name>				# Build image from Dockerfile (current dir)
docker images           			# List images
docker rmi <image>      			# Delete image
docker rmi -f <image>   			# Force delete image
```

### *__CONTAINER MANAGE__*
```bash
docker run <image>       			# Run a container
docker run -d <image>    			# Run in background (detached)
docker run -it <image> sh			# Interactive shell inside container

docker ps   						# Running containers
docker ps -a						# All containers (running + stopped)

docker stop <container>   			# Stop container
docker start <container>  			# Start stopped container
docker restart <container>			# Restart container

docker rm <container>   			# Remove container
docker rm -f <container>			# Force remove running container

docker logs <container>				# View logs

docker exec -it <container> sh		# Enter running container

docker inspect <container>			# Full container info

sudo nsenter --target <pid> --mount --uts --ipc --pid --net --cgroup sh
sudo nsenter --t <pid> -m -u -i -p -n -c sh
```

### *__CLEAN__*

```bash
docker system df					# Disk usage (images, containers, cache)

docker system prune   				# Remove stopped containers + unused networks
docker system prune -a				# Remove EVERYTHING unused (images included)

docker rm -f $(docker ps -aq)		# Delete ALL containers

docker builder prune      			# Remove build cache only
docker builder prune -a -f			# Remove ALL build cache (aggressive)
```

## <u>__COMMAND DOCKER COMPOSE__</u>

### *__IMAGE MANAGE__*
```bash
docker compose -f <f1.yml> -f <f2.yml>	# Combine files than you supply and considerate on one files in order of you supply
docker compose up						# Build (re)creat, start containers
docker compose down --rmi all			# Remove 
docker rmi <image>   					# Delete image
docker rmi -f <image>					# Force delete image
```

### *__CONTAINER MANAGE__*
```bash
docker compose down>					# Run a container

docker compose ps						# Running containers launch by docker compose
docker conpose ps -a					# All containers (running + stopped) launch by docker compose
```

### *__CLEAN__*

```bash
docker compose down	--rmi all					# Stop and remove containers, network, volume (--rmi all remove images) created by docker compose up
```


# __Ressources__

- Learning global containers
	- https://blog.stephane-robert.info/docs/conteneurisation/