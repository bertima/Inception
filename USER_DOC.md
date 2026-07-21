# __Table of Contents__

- [Overview](#overview)
- [Starting and Stopping the Project](#starting-and-stopping-the-project)
  - [Start everything](#start-everything)
  - [Stop everything](#stop-everything)
  - [Restart after a stop](#restart-after-a-stop)
  - [Completely reset the project](#completely-reset-the-project)
- [Accessing the Website](#accessing-the-website)
  - [Accessing the admin panel](#accessing-the-admin-panel)
- [Finding and Managing Credentials](#finding-and-managing-credentials)
- [Checking That Services Are Running Correctly](#checking-that-services-are-running-correctly)
  - [Quick check](#quick-check)
  - [Overall project status](#overall-project-status)
  - [Looking at what a service is doing](#looking-at-what-a-service-is-doing)
  - [Confirming the website itself is reachable](#confirming-the-website-itself-is-reachable)

# __Overview__

This project provides a complete WordPress website, secured with HTTPS, running in an isolated environment made of three components:

- **A website** (WordPress) — where your content lives, and where visitors land.
- **A database** (MariaDB) — stores everything behind the scenes: articles, users, settings.
- **A secure gateway** (Nginx) — the only door into the system, handling encrypted (HTTPS) connections.

You don't need to interact with the database or the gateway directly — everything is accessible through your web browser.

# __Starting and Stopping the Project__

## Start everything

From the project's root folder:

```bash
make
```

This builds and starts all three services. The first launch takes a bit longer (WordPress and the database are being set up); afterwards, starting is quick.

## Stop everything

```bash
make down
```

This stops and removes the running containers. **Your website, articles, and database are kept safe** — they live outside the containers and aren't deleted by this command.

## Restart after a stop

Simply run `make` again — it will detect everything is already configured and start back up without recreating your data.

## Completely reset the project

If you ever want to wipe everything and start fresh (including your website content and database):

```bash
make fclean
```

⚠️ This deletes all your website data and the SSL certificate permanently. Only use this if you really want to start over from zero.

# __Accessing the Website__

Once the project is running, open your browser and go to:

```bash
https://<your_domain>/wp-admin
```

From there, you can log in with the administrator account (see below for where to find the credentials) to write articles, manage pages, install plugins, change settings, etc.

There is also a regular **author account**, which can publish content but doesn't have full administrator rights.

# __Finding and Managing Credentials__

All passwords and login names used by this project are stored as plain text files in the `secrets/` folder, at the root of the project:

| File | What it contains |
|---|---|
| `wp_admin_name.txt` | Administrator username (WordPress admin panel) |
| `wp_admin_password.txt` | Administrator password |
| `wp_admin_email.txt` | Administrator email |
| `wp_user.txt` | Regular author username |
| `wp_user_password.txt` | Regular author password |
| `wp_user_email.txt` | Regular author email |
| `db_user.txt` | Database username (technical, not needed to browse the site) |
| `db_user_password.txt` | Database user password |
| `db_root_password.txt` | Database root password (technical, administrative use only) |

To read a password, simply open the corresponding file, for example:

```bash
cat secrets/wp_admin_password.txt
```

⚠️ These files contain sensitive information. Never share them, and never commit this folder to a public repository.

# __Checking That Services Are Running Correctly__

## Quick check

From the project's `srcs/` folder:

```bash
docker compose ps
```

This lists the three containers (`mariadb`, `wordpress`, `nginx`) along with their status. You want to see `healthy` (or `running`) next to each one. If one shows `unhealthy` or `restarting`, something is wrong with that service.

## Overall project status

```bash
make status
```

Shows all containers, images, volumes, and networks currently on the machine, plus disk usage — useful for a broader health check.

## Looking at what a service is doing

If a service isn't behaving as expected, you can check its logs:

```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
```

Add `-f` to follow the logs in real time, e.g. `docker logs -f wordpress`.

## Confirming the website itself is reachable

The simplest check is opening `https://<your_domain>` in a browser. If the page loads (even with the certificate warning mentioned above), the whole chain — Nginx, WordPress, and the database — is working correctly.