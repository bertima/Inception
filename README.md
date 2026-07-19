*This project has been created as part of the 42 curriculum by bertrmar.*

# Inception

# __Table of Contents__

- [Description](#description)
- [Project description](#project-description)
  - [Architecture](#architecture)
  - [Design choices](#design-choices)
  - [Virtual Machines vs Docker](#virtual-machines-vs-docker)
  - [Secrets vs Environment Variables](#secrets-vs-environment-variables)
  - [Docker Network vs Host Network](#docker-network-vs-host-network)
  - [Docker Volumes vs Bind Mounts](#docker-volumes-vs-bind-mounts)
- [Instructions](#instructions)
- [Resources](#resources)

# __Description__

Inception is a system administration project from the 42 curriculum. The goal is to build a small, secure web infrastructure entirely with Docker, using containers you configure and write yourself rather than off-the-shelf pre-built images.

The stack sets up a complete WordPress website, backed by a MariaDB database, served through Nginx over HTTPS — three services, each in its own container, communicating over a private Docker network. The project is meant to teach the fundamentals of containerization: writing Dockerfiles from a bare base image, orchestrating multiple services with Docker Compose, managing secrets properly, and persisting data outside the container lifecycle.

For a step-by-step technical setup guide, see [DEV_DOC.md](./DEV_DOC.md). For day-to-day usage (starting the site, finding credentials, checking that it's running), see [USER_DOC.md](./USER_DOC.md).

# __Project description__

## __Architecture__

Three containers, each built from `alpine:3.23`, connected through a single private Docker network (`inception`):

- **MariaDB** — the database backend. Initializes itself on first boot (root password, database, application user), then serves connections only inside the private network.
- **WordPress** — runs `php-fpm` only, no bundled web server. Installs and configures the site via WP-CLI on first boot, using credentials injected as Docker secrets.
- **Nginx** — the single entry point, terminating HTTPS with a self-signed certificate and forwarding PHP requests to WordPress via FastCGI.

Only Nginx exposes a port to the host; MariaDB and WordPress are reachable exclusively from inside the Docker network.

## __Design choices__

- Every image is built **from scratch** from `alpine:3.23` — no pre-built `mariadb`, `wordpress`, or `nginx` Docker Hub images, as required by the subject. This keeps images minimal and forces an explicit understanding of what each service actually needs.
- **Secrets** (passwords, usernames, emails) are never hardcoded or passed as plain environment variables — they're mounted as Docker secrets, read from files at runtime.
- **Configurable ports and domain** are centralized in a single `.env` file, so nothing about a specific machine or user is hardcoded into the Dockerfiles or configs.
- **Data persistence** is handled through bind-mounted volumes on the host, so containers can be destroyed and recreated without losing the website or its database.
- **Startup order** is enforced with `healthcheck` + `depends_on: condition: service_healthy`, so WordPress never tries to reach a database that isn't ready, and Nginx never starts before WordPress can actually answer requests.

## __Virtual Machines vs Docker__

A Virtual Machine emulates an entire computer, including its own kernel, running on top of a hypervisor — heavier, slower to start, but fully isolated at the hardware/OS level. Docker containers instead share the host's kernel and only package the application and its dependencies, making them far lighter and faster to start (seconds instead of minutes), at the cost of slightly weaker isolation than a full VM.

For this project, Docker is the appropriate choice: we need three lightweight, disposable, quickly-restartable services rather than three fully independent operating systems, and Docker Compose lets us describe and orchestrate all three declaratively in a single file.

## __Secrets vs Environment Variables__

Plain environment variables (`environment:` in Compose) are visible to anyone with access to the container's process list, `docker inspect` output, or the compose file itself — not ideal for passwords. Docker secrets are instead mounted as files inside the container (under `/run/secrets/`), readable only by the process that needs them, and never appear in `docker inspect` or in the image layers.

In this project, all passwords, usernames, and emails are handled as Docker secrets, read from files in a `secrets/` folder kept out of version control. Non-sensitive configuration (domain name, database name, ports) uses regular environment variables via `.env`, since there's no confidentiality concern there.

## __Docker Network vs Host Network__

With `network_mode: host`, a container shares the host's network stack directly — no isolation, and every port the container binds becomes immediately reachable on the host. A custom Docker network (the default here, via a bridge driver) instead gives containers their own private, isolated network segment, with internal DNS resolution by container name and no exposure to the host unless explicitly published.

This project uses a custom bridge network (`inception`) rather than the host network: MariaDB and WordPress are never exposed outside the Docker network at all, and only Nginx explicitly publishes a port to the host. This matches the principle of least exposure — the database has no business being reachable directly from outside.

## __Docker Volumes vs Bind Mounts__

Both persist data outside a container's writable layer, but differently. A **named volume** is fully managed by Docker (stored under `/var/lib/docker/volumes/...`), portable across environments, and the recommended default for most use cases. A **bind mount** maps a specific, user-chosen path on the host filesystem directly into the container — more explicit and easier to inspect/back up manually, but tied to that host's exact directory structure.

This project uses named volumes configured with bind-mount-style driver options (`driver: local`, `driver_opts: type: none, o: bind`), pointing to fixed folders under `/home/$USER/data/`. This hybrid gives the convenience of referencing volumes by name in Compose, while keeping the actual data at a known, easily inspectable location on the host — useful for backups and for satisfying the subject's requirement that data survive container removal.

# __Instructions__

Full setup steps (installing Docker, configuring `.env`, secrets, etc.) are documented in [DEV_DOC.md](./DEV_DOC.md). Quick summary:

```bash
git clone <repo-url> inception && cd inception
# create srcs/.env and secrets/ (see DEV_DOC.md)
make
```

The site will then be reachable at `https://<your_domain>`. See [USER_DOC.md](./USER_DOC.md) for using the site day-to-day, and the [Makefile](#) section of DEV_DOC.md for `make down`, `make clean`, `make fclean`, etc.

# __Resources__

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Docker secrets documentation](https://docs.docker.com/engine/swarm/secrets/)
- [WP-CLI documentation](https://wp-cli.org/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [Nginx documentation](https://nginx.org/en/docs/)
- [Alpine Linux packages](https://pkgs.alpinelinux.org/packages)

**AI usage:** AI assistance (Claude) was used throughout this project to review and debug configuration files (Dockerfiles, entrypoint scripts, `docker-compose.yml`, `nginx.conf`) — identifying syntax errors (e.g. shell quoting issues, malformed CLI flags), inconsistencies between files (e.g. a configurable port declared in `.env` but not actually wired through every service that needed it), and to help structure and review this documentation (`DEV_DOC.md`, `USER_DOC.md`, `README.md`). All architecture decisions, the actual Dockerfiles, scripts, and configuration content were written and tested by the author; AI was used as a reviewer/debugging aid, not as the original author of the infrastructure.