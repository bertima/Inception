# __Table of Contents__

- [Overview](#overview)
- [Prerequisites](#prerequisites)
  - [System Requirements](#1-system-requirements)
  - [Install Docker and Docker Compose](#1-installation-docker-and-docker-compose)
  - [Add user to Docker group](#2-add-your-user-to-the-docker-group)
  - [Verify installation](#3-verification-of-installation)
  - [Clone repository](#4-clone-repository)
  - [Environment variables and secrets](#5-setup-domain-name-environment-variables-and-secret)


# __Overview__

This project sets up a complete web infrastructure using Docker Compose. The architecture is composed of three containers connected through a private Docker network:

- MariaDB, which manages the database.
- WordPress, which provides the website.
- NGINX, which acts as a reverse proxy, handling client connections and serving the website through HTTPS.

The goal is to create a secure and isolated web environment using containerization.

# __Prerequisites__

## __1. System Requirements__

## <u>*__Machine__*</u>
- Linux distribution (Debian 13 "Trixie" was used to create this project)
- Minimum 2GB RAM (4GB is more comfortable)
- Minimum 14GB of free disk space (less may be enough with a lighter distribution)
- Sudo access

## <u>*__Software__*</u>

### __1. Installation of Docker and Docker Compose__

First, install curl:
```bash
sudo apt-get install -y curl
```

Then install Docker using the official Docker installation script:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh 
```
|Part|Description|
|-----|-----|
|curl|Download a file from the Internet|
|-f|Fail if the HTTP request returns an error|
|-s|Silent mode|
|-S|Display errors even when using silent mode|
|-L|Follow HTTP redirections|
|-o get-docker.sh|Save the script in name of get-docker.sh|
|||  

This command install :
|Component|Description|
|-----|-----|
|docker-ce|Docker Engine. Creates, runs and manages containers, images, networks and volumes|
|dockerd|Docker daemon. Background Linux service that receives Docker commands and manages Docker resources|
|docker-ce-cli|Command line interface used to communicate with Docker Engine|
|containerd.io|Container runtime manager. Handles image management and container lifecycle|
|runc|Low-level container runtime responsible for Linux isolation using namespaces and cgroups|
|docker-buildx-plugin|Advanced image builder based on BuildKit. Supports improved caching and multi-platform builds|
|docker-compose-plugin|Allows orchestration and management of multiple containers using docker compose|
|Docker GPG key in /etc/apt/keyrings/|Verifies that Docker packages come from the official Docker repository and have not been modified|

```bash
         Docker Compose
              |
              v
          Docker CLI (not always)
              |
              v
          Docker API
              |
              v
        Docker Engine
              |
              v
           dockerd
              |
              v
        containerd
              |
              v
            runc
              |
              v
       Isolated Linux process
```

### __2. Add your user to the Docker group__

By default, Docker commands require root privileges.  
To use Docker without sudo, add your user to the Docker group:

```bash 
sudo usermod -aG docker $USER
```
Then restart your session or apply the new group:

```bash
newgrp docker
```

This allows your user to communicate directly with the Docker daemon.

### __3. Verification of installation__

Check Docker and Docker Compose versions:

```bash
docker --version
docker compose version
```

Test Docker by running the official test container:

```bash
docker run hello-world
```

This command:

- Downloads the hello-world image from Docker Hub if it is not already available locally.
- Creates a temporary container from this image.
- Runs the container.
- Displays a confirmation message.
- Stops the container after execution. The stopped container remains visible with `docker ps -a` until manually removed.

### __4. Clone repository__

```bash
git clone <repo-url> <name>
```

Move into the project directory:

```bash
cd <name>
```

### __5. Setup domain name environment variables and secret__

#### __Environment file__

Create the .env file at the root of the repository 
:
```bash
touch .env
```
Open it with your preferred editor:

```bash
vim .env
```

Your file must contain:

```bash
DOMAIN_NAME=login.42.fr
DB_NAME=example_db_name
WP_TITLE=example_title
```
Fill each variable with your own values.

#### __Secrets folder__

Create the secret folder at the root of the project:

```bash
mkdir -p secret && cd secret && \
touch db_root_password.txt && \
touch db_user_password.txt && \
touch db_user.txt && \
touch wp_admin_email.txt && \
touch wp_admin_name.txt && \
touch wp_admin_password.txt && \
touch wp_user_email.txt && \
touch wp_user_password.txt && \
touch wp_user.txt
```

Each file must contain only one value.

Example: secret/wp_admin_password.txt

```bash
My_admin_1_password
```

These files contain sensitive information used by Docker containers during initialization.

They should never be committed to a public repository.

#### __Domain name__

This allows your local machine to resolve login.42.fr to your local server.  
Make sure your domain name is added to the host machine's hosts file:

```bash
sudo vim /etc/hosts
```

Add:

```bash
127.0.0.1 login.42.fr
```