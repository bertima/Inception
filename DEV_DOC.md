# __Table of Contents__

- [Prerequisites](#prerequisites)
  - [System Requirements](#system-requirements)
  - [Install Docker](#install-docker)
  - [Clone repository](#clone-repository)
  - [Secrets folder and .env file](#secrets-folder-and-env-file)
- [Architecture](#architecture)
  - [Services](#services)
  - [Network](#network)
  - [Ports and .env](#ports-and-env)
- [Launch project](#launch-project)
  - [Makefile](#makefile)
- [Useful commands](#useful-commands)
- [Data persistence](#data-persistence)

# __Prerequisites__

## __System Requirements__

- Linux distribution (Debian 13 "Trixie" was used to create this project)
- Minimum 2GB RAM (4GB more comfortable) 
- Minimum 14GB of free disk space
- Sudo access

## __Install Docker__

```bash
sudo apt-get install -y curl
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo usermod -aG docker $USER && newgrp docker
docker --version && docker compose version
```

## __Clone repository__

```bash
git clone <repo-url> <name> && cd <name>
```
Structure :
```bash
.
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
## __Secrets folder and .env file__

⚠️⚠️ __Never commit `.env` or `secrets/` to a public repository — add them to `.gitignore`.__ ⚠️⚠️

**`.env`** goes in `srcs/.env` (the Makefile and `docker compose` both run from `srcs/`):

```bash
touch srcs/.env
```
```bash
DOMAIN_NAME=bertrmar.42.fr
DB_NAME=wordpress
WP_TITLE=Inception
NGINX_PORT=443
WP_PORT=9000
DB_PORT=3306
```

Put a literal value for `DOMAIN_NAME` (e.g. `bertrmar.42.fr`), not a shell expression — `.env` is read as plain text, no command substitution happens. Run `whoami` to get the right value. The Makefile reads this same value (`-include srcs/.env`), so `/etc/hosts` and the certificate's `CN` always match it automatically.

**`secrets/`** goes at the repo root (compose references `../secrets/<file>.txt`):

```bash
mkdir -p secrets && cd secrets && \
touch db_root_password.txt db_user_password.txt db_user.txt \
      wp_admin_email.txt wp_admin_name.txt wp_admin_password.txt \
      wp_user_email.txt wp_user_password.txt wp_user.txt
```

Each file must contain a single value, no newline needed:
```bash
My_admin_1_password
```

`make` adds the domain to `/etc/hosts` for you automatically (target `check_domain`), reading `DOMAIN_NAME` from `srcs/.env`.

# __Architecture__

Three containers on a private network:

## __Services__

- **MariaDB** — database backend. Secrets provide root/user passwords. Data in `maria_db` volume (`/var/lib/mysql`). No host port exposed.
- **WordPress** — `php-fpm` only, no bundled web server (port `9000`, internal only). Installed via WP-CLI on first start using secrets. Files in `wp_data` (`/var/www/html`), shared with nginx.
- **Nginx** — single entry point, HTTPS on `443` internally, mapped to `${NGINX_PORT}` on the host. Reads the TLS cert from `nginx_data` (`/etc/nginx/ssl`) — nginx does **not** generate it itself (see [Data persistence](#data-persistence)).

`depends_on` + `healthcheck` enforce startup order: `mariadb` → `wordpress` → `nginx`, each waiting for the previous one to be actually ready, not just started.

## __Network__

```yaml
networks:
  inception:
    driver: bridge
```

- Containers resolve each other **by `container_name`** via Docker's embedded DNS (e.g. `WORDPRESS_DB_HOST=mariadb`).
- Isolated from other Docker projects on the host.
- Only `nginx` publishes a port (`${NGINX_PORT}:443`) — `mariadb` and `wordpress` are reachable only from inside `inception`, never directly from outside.
- Inspect with `docker network inspect inception`.

## __Ports and .env__

Only `NGINX_PORT` is wired into compose (`"${NGINX_PORT}:443"`). To change it:

```bash
# edit NGINX_PORT in srcs/.env, then:
cd srcs && docker compose up -d nginx   # no rebuild needed
```

Browse to `https://bertrmar.42.fr:<new_port>`.

# __Launch project__

## __Makefile__

|COMMAND|DESCRIPTION|
|----|----|
|`make` / `make all`|Full setup (env, domain, volumes, certificate) then build + start|
|`make build`|Build images only|
|`make up`|Build (if needed) + start|
|`make down`|`docker compose down -v --rmi all` — stops/removes **this project's** containers, volumes, images only|
|`make status`|Containers, images, volumes, networks, disk usage|
|`make clean`|⚠️ Removes **every** container, image, and volume **on the machine** (not project-scoped), plus custom networks. Does not touch build cache.|
|`make fclean`|`clean` + deletes `/home/$USER/data/` (incl. certificate) + prunes build/buildx cache|
|`make re` / `make fre`|`clean`/`fclean` then `all`|

Recommended for everyday use: `make` once, then `make up` / `make down` (project-scoped, safe). Reserve `make clean`/`fclean` for when you're fine wiping every Docker image/volume on the whole machine.

# __Useful commands__

*(from `srcs/`)*

|COMMAND|DESCRIPTION|
|-|-|
|`docker compose ps`|Status/health/ports of project services|
|`docker compose logs -f <service>`|Follow logs of one service|
|`docker compose up -d --build <service>`|Rebuild + restart a single service|
|`docker compose restart <service>`|Restart without rebuilding|
|`docker exec -it <container> sh`|Shell into a running container|
|`docker inspect <container>`|Network, mounts, env vars, healthcheck status|
|`docker volume inspect <volume>`|Where a volume actually lives on the host|
|`docker network inspect <network>`|Containers attached + their internal IPs|
|`docker stats`|Live CPU/RAM per container|

# __Data persistence__

| Volume | Written by | Container path | Host path |
|---|---|---|---|
| `wp_data` | WordPress (read by Nginx) | `/var/www/html` | `/home/$USER/data/html/` |
| `mariadb_data` | MariaDB | `/var/lib/mysql` | `/home/$USER/data/mariadb/` |
| `nginx_data` | **Not a container** — generated on the host by `make`'s `check_certificate` (openssl, `CN=$(whoami).42.fr`) before containers start; nginx only reads it | `/etc/nginx/ssl` | `/home/$USER/data/nginx/` |

These folders live on the host filesystem: `make down` and `make clean` don't touch them. Only `make fclean` deletes `/home/$USER/data/` (certificate regenerated on next `make`).