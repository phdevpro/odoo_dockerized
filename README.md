# Odoo Dockerized (Odoo 18)

Compact guide to run, develop, and deploy Odoo 18 with Docker and PostgreSQL.

## Prerequisites
- Docker Desktop with Compose v2.
- Free port: `8069` (Odoo), optional `8071`, `8072`.
- Windows/macOS/Linux.

## Quick Start
1. Build images:
   - `docker compose build`
2. Start services:
   - `docker compose up -d`
3. Open web UI:
   - `http://localhost:8069`

## Database
- Postgres credentials (compose):
  - `POSTGRES_USER=odoo`, `POSTGRES_PASSWORD=odoo`, `POSTGRES_DB=postgres`.
- Odoo DB connectivity:
  - The stack is configured to probe the server using `DB_NAME=postgres`.
  - Create your business database from the Odoo web UI (Manage Databases) or via CLI.
- Create a database (CLI examples):
  - `docker compose exec db createdb -U odoo <DB_NAME>`
  - or: `docker compose exec db psql -U odoo -c "CREATE DATABASE <DB_NAME> ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8'"`
- Upgrade schema/modules (after version upgrades or new addons):
  - `docker compose run --rm odoo odoo -d <DB_NAME> -u all --stop-after-init`

## Project Layout
- `Dockerfile`: builds Odoo 18 (nightly `.deb`) on Debian bookworm.
- `docker-compose.yml`: `db` (Postgres) and `odoo` services, volumes, env vars.
- `entrypoint.sh`: waits for DB, auto-installs/updates addons, starts Odoo.
- `odoo.conf`: base config (paths, minimal options).
- `wait-for-psql.py`: PostgreSQL readiness helper.
- `extra-addons/`: your custom addons (mounted in development).

## Addons (Development)
- Bind mount: `./extra-addons:/mnt/extra-addons` (already in compose).
- Boot automation (env in compose):
  - `AUTO_INSTALL=true`: install discovered addons under `/mnt/extra-addons`.
  - `AUTO_UPDATE=true`: update addons.
  - `DEV_RELOAD=true`: enable `--dev=reload` for hot-reload.
- Targeted operations:
  - `INSTALL_MODULES=mod_a,mod_b` to install specific modules.
  - `UPDATE_MODULES=mod_c` to update specific modules.
- Discovery: directories with `__manifest__.py` (or `__openerp__.py`).

## Production (tips)
- Bake addons into the image; avoid code mounts:
  ```Dockerfile
  # Dockerfile.prod (example)
  FROM odoo_dockerized:local
  COPY extra-addons /mnt/extra-addons
  # If you use Python requirements
  RUN pip3 install --no-cache-dir -r /mnt/extra-addons/requirements.txt --break-system-packages
  ```
- Build: `docker build -f Dockerfile.prod -t odoo_app:prod .`
- Remove `./extra-addons:/mnt/extra-addons` from compose in prod.
- Keep `AUTO_UPDATE=true` or use `UPDATE_MODULES` for first boot migrations.

## Environment Variables (service odoo)
- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`.
- `AUTO_INSTALL`, `AUTO_UPDATE`, `DEV_RELOAD`.
- `INSTALL_MODULES`, `UPDATE_MODULES`.
- `EXTRA_ADDONS_DIR` (default `/mnt/extra-addons`).
- `ODOO_RC` (default `/etc/odoo/odoo.conf`).

## Useful Commands
- App logs: `docker compose logs -f odoo`
- DB logs: `docker compose logs -f db`
- Rebuild & restart: `docker compose up -d --build`
- Update all modules: `docker compose run --rm odoo odoo -d <DB_NAME> -u all --stop-after-init`

## Troubleshooting
- `FATAL: database "<name>" does not exist`: create the database or use the web UI.
- Errors like `res_lang.short_time_format does not exist`: run a full `-u all` after upgrading Odoo.
- `wkhtmltopdf` rendering issues on bookworm: replace with a compatible `.deb` if you need the patched Qt build.
- Compose warning "version is deprecated": remove `version: "3.8"` from `docker-compose.yml`.

## Odoo Version Pinning
- Currently using `odoo_18.0.latest_all.deb` (nightly). To pin, replace the `.deb` URL in `Dockerfile` and optionally verify checksum.

## Odoo Configuration
- File: `/etc/odoo/odoo.conf` (`ODOO_RC`).
- For production set `admin_passwd`, `workers > 0`, and `proxy_mode` when behind a proxy.

---
Questions or changes (prod override, version pinning, CI/CD)? Open an issue or ask.