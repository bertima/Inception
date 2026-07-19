# __Table of Contents__

# __Table of Contents__

- [Prerequisites](#prerequisites)
  - [System Requirements](#1-system-requirements)
  - [Install Docker and Docker Compose](#1-installation-of-docker-and-docker-compose)
  - [Add user to Docker group](#2-add-your-user-to-the-docker-group)
  - [Verify installation](#3-verification-of-installation)
  - [Clone repository](#4-clone-repository)
  - [Secrets folder and .env file](#5-secrets-folder-and-env-file)
- [Dockerfile / Docker Compose](#dockerfile--docker-compose)
  - [Dockerfile](#dockerfile)
    - [WordPress](#wordpress)
    - [Nginx](#nginx)
    - [MariaDB](#mariadb)
  - [docker-compose.yml](#docker-composeyml)
    - [Services description](#services-description)
- [Launch project](#launch-project)
  - [Makefile](#makefile)
    - [Main commands](#main-commands-)

# __Prerequisites__

## __1. System Requirements__

## <u>__Machine__</u>

- Linux distribution (Debian 13 "Trixie" was used to create this project)
- Minimum 2GB RAM (4GB is more comfortable)
- Minimum 14GB of free disk space (less may be enough with a lighter distribution)
- Sudo access

## <u>__File and Software__</u>

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

### __4. Clone repository__

```bash
git clone <repo-url> <name>
```

Move into the project directory:

```bash
cd <name>
```

Your directory should look like this :  

```bash
.
├── DEV_DOC.md
├── Makefile
├── README.md
├── srcs
│   ├── docker-compose.yml
│   └── requirements
│       ├── mariadb
│       │   ├── conf
│       │   │   └── maria-server.cnf
│       │   ├── Dockerfile
│       │   └── tools
│       │       └── entrypoint_mariadb.sh
│       ├── nginx
│       │   ├── conf
│       │   │   └── nginx.conf
│       │   ├── Dockerfile
│       │   └── tools
│       │       └── entrypoint_nginx.sh
│       └── wordpress
│           ├── conf
│           ├── Dockerfile
│           └── tools
│               └── entrypoint_wordpress.sh
└── USER_DOC.md
```

### 5. __Secrets folder and .env file__

⚠️⚠️ __They should never be committed to a public repository. For security add them to the git ignore__ ⚠️⚠️

#### <u>*__File .env__*</u>

Create the .env file in the srcs folder of the repository:

```bash
touch srcs/.env
```
Open it with your preferred editor:

```bash
vim srcs/.env
```

Your file must contain:

```bash
DOMAIN_NAME=bertrmar.42.fr

DB_NAME=wordpress

WP_TITLE=Inception

NGINX_PORT=443
WP_PORT=9000
DB_PORT=3306
```

Fill each variable with your own values. Ports use the default port, except nginx for the HTTPS connection.


#### <u>*__Secrets folder__*</u>

Create the secret folder at the root of the project:

```bash
mkdir -p secrets && cd secrets && \
touch db_root_password.txt \
	  db_user_password.txt \
	  db_user.txt \
	  wp_admin_email.txt \
	  wp_admin_name.txt \
	  wp_admin_password.txt \
	  wp_user_email.txt \
	  wp_user_password.txt \
	  wp_user.txt
```

Each file must contain only one value.

Example: secret/wp_admin_password.txt

```bash
My_admin_1_password
```

These files contain sensitive information used by Docker containers during initialization.

#### __Domain name__

`make` handles this step for you automatically (target `check_domain`): it reads `DOMAIN_NAME` from `srcs/.env`, checks `/etc/hosts` for that value, and appends `127.0.0.1 <DOMAIN_NAME>` if missing. You only need to do it manually if you're not using `make`:

```bash
sudo vim /etc/hosts
```
Add:
```bash
127.0.0.1 bertrmar.42.fr
```


# __Building and orchestrating the containers__

## Dockerfile

Before containers can run together, each image needs to be built. A `Dockerfile` is a text file containing a list of instructions used to build a Docker image. Each instruction (`FROM`, `RUN`, `COPY`, `EXPOSE`, `ENTRYPOINT`...) adds a step: installing packages, copying files, setting configuration, or defining what command runs when a container starts. Once built, this image becomes the template used to create and run containers.

Each service in this project has its own `Dockerfile`, based on `alpine:3.23`. Here is what each one does, step by step.

### WordPress

1. Installs PHP 8.3 with the extensions WordPress needs (`mysqli`, `gd`, `curl`, `mbstring`...) plus `mariadb-client` (to test the connection to the database).  

2. Sets PHP's memory limit to 256M, and changes `php-fpm` config so it listens on port `9000` on all interfaces (not just `127.0.0.1`, otherwise Nginx couldn't reach it from another container).
3. Downloads WP-CLI, the command-line tool used to install and configure WordPress.
4. Copies the entrypoint script and makes it executable.
5. `EXPOSE 9000` — documents that this container listens on port 9000 (php-fpm/FastCGI).
6. On start, runs `entrypoint_wordpress.sh`.

### Nginx

1. Installs `nginx`.

2. Creates `/run/nginx`, required by nginx to start properly.
3. Copies the nginx configuration file and the entrypoint script.
4. `EXPOSE 443` — documents that this container listens on port 443 (HTTPS).
5. On start, runs `entrypoint_nginx.sh`.

### MariaDB

1. Installs `mariadb` and `mariadb-client`.

2. Copies the entrypoint script and the custom server configuration (`maria-server.cnf`).
3. `EXPOSE 3306` — documents that this container listens on port 3306 (MySQL/MariaDB default port).
4. On start, runs `entrypoint_mariadb.sh`.

## __docker-compose.yml__

`docker-compose.yml` (in `srcs/`) brings the three images together: it builds them, links them, and starts them with a single command.

This file defines:
- Services
- Networks
- Volumes
- Secrets
- Service dependencies (via `depends_on` + `healthcheck`, ensuring `mariadb` → `wordpress` → `nginx` start in the right order and only once each previous one is actually ready)


### __Services description__

- __Nginx__

  Single entry point of the infrastructure. Listens on port `443` (HTTPS, TLSv1.2/1.3, self-signed certificate) and forwards PHP requests to WordPress via FastCGI on port `9000`. Serves static files from the shared `wp_data` volume.

- __WordPress__

  Runs WordPress with `php-fpm` (no bundled web server). On first start, installs WordPress via WP-CLI (site, admin, and author accounts) using credentials from Docker secrets, then serves on port `9000`. Files persist in the `wp_data` volume, shared with nginx.

- __MariaDB__

  Database backend for WordPress. On first start, initializes the server with networking disabled to safely set up the root password, database, and application user, then restarts with networking enabled. Data persists in the `mariadb_data` volume; passwords come from Docker secrets.

### __Network__

All three services share a single custom bridge network named `inception`:

```yaml
networks:
  inception:
    driver: bridge
```

What this gives you:

- Containers resolve each other **by `container_name`**, not by IP — that's why `WORDPRESS_DB_HOST=mariadb` works: Docker's embedded DNS resolves `mariadb` to the container's internal IP on the `inception` network.
- The network is isolated from other Docker networks/projects on the same host — a container from another `docker-compose` project can't reach `mariadb` or `wordpress` directly.
- Only `nginx` publishes a port to the host (`${NGINX_PORT}:443`). `mariadb` and `wordpress` have no `ports:` section at all, so they're reachable **only from inside `inception`** — the database and PHP-FPM are never directly exposed to the outside world, only through Nginx.
- You can inspect it once containers are up: `docker network inspect inception` shows every container attached, with its internal IP.

## __Ports and .env__

All host-facing ports are centralized in `.env` and injected into `docker-compose.yml` through variable substitution, for example:

```yaml
services:
  nginx:
    ports:
      - "${NGINX_PORT}:443"
```

To change a port:

1. Edit the corresponding variable in `srcs/.env` (e.g. `NGINX_PORT=8443`).
2. Restart the affected service so Compose re-reads the mapping:
```bash
   cd srcs && docker compose up -d nginx
```
   (No rebuild needed — port mapping is not baked into the image.)
3. Don't forget to browse to the new port, e.g. `https://bertrmar.42.fr:8443`, and update `/etc/hosts` only if you also changed `DOMAIN_NAME`.

# __Launch project__

|COMMAND|DESCRIPTION|
|-|-|
|docker logs <container>|Show logs of the containers (with -f in real time)|
|||

## __Makefile__

The Makefile at the root of the project handles the full setup, build, and cleanup process.

### __Main commands :__

|COMMAND|DESCRIPTION|
|----|----|
|make (= make all)| Runs `check_config` (env, domain, volume folders, certificate) then `up`: builds and starts all containers|
|make build|Builds the Docker images from the Dockerfiles, without starting containers|
|make up|Builds the images (if needed) and starts the containers (`docker compose up --build -d`)|
|make version|Prints Docker and Docker Compose versions|
|make status|Displays all containers, images, volumes, networks, and Docker disk usage|
|make down|`docker compose down -v --rmi all` — stops and removes **this project's** containers, volumes, and images only|
|make clean|`suppress` + `remove_network` + `remove_volume` — ⚠️ stops/removes **every** container on the machine, removes **every** Docker image on the machine, and removes **every** Docker volume on the machine (not scoped to this project). Also removes custom networks. Does *not* touch the build cache.|
|make fclean|Runs `clean`, then also removes the local bind-mount data (`/home/$USER/data/`, including the SSL certificate) and prunes the build cache/buildx cache (`docker system prune -af --volumes`, `docker buildx prune -af`)|
|make re|`clean` then `all`|
|make fre|`fclean` then `all`|
|||

Recommended order for everyday use:
1. `make` (first time only)
2. `make up` / `make down` while developing — scoped to this project, keeps other Docker projects on the machine untouched
3. `make clean` only if you're fine wiping every Docker image/volume on the whole machine
4. `make fclean` only when you want to wipe everything, including your local data and the certificate

## __Docker Compose raw commands__

The Makefile covers the common cases, but it's useful to know the underlying Docker Compose commands, for example to restart a single service or debug something without tearing down the whole stack.

```bash
# Go to where docker-compose.yml lives
cd srcs

# Start everything in background, rebuilding images if a Dockerfile changed
docker compose up -d --build

# Start without rebuilding
docker compose up -d

# Stop and remove containers (keeps volumes, so data is kept)
docker compose down

# Stop and remove containers AND volumes (data is lost)
docker compose down -v

# Rebuild and restart only one service (e.g. after a nginx.conf change)
docker compose up -d --build nginx

# Restart a service without rebuilding (e.g. after an .env port change)
docker compose restart nginx

# View running services and their status/ports
docker compose ps

# Follow logs of one service
docker compose logs -f wordpress

# Follow logs of all services
docker compose logs -f
```

# __Managing containers and volumes__

|COMMAND|DESCRIPTION|
|-|-|
|`docker ps`|List running containers|
|`docker ps -a`|List all containers, including stopped ones|
|`docker logs <container>`|Show logs of a container (add `-f` to follow in real time)|
|`docker exec -it <container> sh`|Open a shell inside a running container, useful for debugging (e.g. `docker exec -it wordpress sh`)|
|`docker inspect <container>`|Show detailed low-level info (network, mounts, env vars) about a container|
|`docker volume ls`|List all Docker volumes|
|`docker volume inspect <volume>`|Show where a volume's data actually lives on the host (`Mountpoint`)|
|`docker network ls`|List Docker networks|
|`docker network inspect <network>`|Show which containers are attached to the private network and their internal IPs|
|`docker stats`|Live view of CPU/RAM usage per container|
|||

# __Data persistence__

Three named volumes, all bind-mounted to real folders on the host:

| Volume | Written by | Mounted to (container) | Host path |
|---|---|---|---|
| `wp_data` | WordPress (read by Nginx too) | `/var/www/html` | `/home/$USER/data/html/` |
| `mariadb_data` (compose name `maria_db`) | MariaDB | `/var/lib/mysql` | `/home/$USER/data/mariadb/` |
| `nginx_data` | **Not written by a container.** Generated on the host by `make`'s `check_certificate` target, using `openssl req -x509 ...` with `CN=$(USER).42.fr`, before any container starts. Nginx only reads the resulting `.crt`/`.key` from `/etc/nginx/ssl`. | `/etc/nginx/ssl` | `/home/$USER/data/nginx/` |

These folders (and the certificate) are created by `make` on first run, via `check_path_volume` and `check_certificate`.

Because they live on the host filesystem, **`make down` (project-scoped) does not delete this data** — you can rebuild and restart the stack and find your WordPress site exactly as you left it.

`make clean` also does **not** delete `/home/$USER/data/` (it only removes containers/images/volumes/networks). Only `make fclean` (target `remove_volume_local`) actually deletes `/home/$USER/data/` — including the certificate, which will be regenerated on the next `make`/`make all`.
