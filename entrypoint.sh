#!/bin/bash
set -e

# If DB env vars provided, wait for Postgres to be ready
if [[ -n "${DB_HOST}" ]]; then
  /usr/local/bin/wait-for-psql.py \
    --host "${DB_HOST}" \
    --port "${DB_PORT:-5432}" \
    --user "${DB_USER:-odoo}" \
    --password "${DB_PASSWORD:-odoo}" \
    --database "${DB_NAME:-postgres}"
fi

# Default to running Odoo with the configured rc file
# Build Odoo DB args from env
ODOO_ARGS=()
if [[ -n "${DB_HOST}" ]]; then
  ODOO_ARGS+=(--db_host "${DB_HOST}")
  ODOO_ARGS+=(--db_port "${DB_PORT:-5432}")
  ODOO_ARGS+=(--db_user "${DB_USER:-odoo}")
  ODOO_ARGS+=(--db_password "${DB_PASSWORD:-odoo}")
fi

# Enable dev auto-reload if requested
if [[ "${DEV_RELOAD,,}" == "true" || "${DEV_RELOAD}" == "1" ]]; then
  ODOO_ARGS+=(--dev=reload)
fi

# Helper: discover modules in extra-addons
EXTRA_ADDONS_DIR="${EXTRA_ADDONS_DIR:-/mnt/extra-addons}"
discover_modules() {
  local dir="${1:-$EXTRA_ADDONS_DIR}"
  local mods=()
  local m
  for m in "$dir"/*; do
    if [[ -d "$m" && ( -f "$m/__manifest__.py" || -f "$m/__openerp__.py" ) ]]; then
      mods+=("$(basename "$m")")
    fi
  done
  IFS=','; echo "${mods[*]}"
}

# Optionally install or update modules automatically before starting
if [[ "${AUTO_INSTALL,,}" == "true" || "${AUTO_INSTALL}" == "1" || -n "${INSTALL_MODULES}" ]]; then
  modules="${INSTALL_MODULES:-$(discover_modules "$EXTRA_ADDONS_DIR")}"
  if [[ -n "$modules" ]]; then
    odoo "${ODOO_ARGS[@]}" -c "${ODOO_RC:-/etc/odoo/odoo.conf}" -d "${DB_NAME:-postgres}" -i "$modules" --stop-after-init
  fi
fi

if [[ "${AUTO_UPDATE,,}" == "true" || "${AUTO_UPDATE}" == "1" || -n "${UPDATE_MODULES}" ]]; then
  modules="${UPDATE_MODULES:-$(discover_modules "$EXTRA_ADDONS_DIR")}"
  if [[ -n "$modules" ]]; then
    odoo "${ODOO_ARGS[@]}" -c "${ODOO_RC:-/etc/odoo/odoo.conf}" -d "${DB_NAME:-postgres}" -u "$modules" --stop-after-init
  fi
fi

if [[ "$1" == "odoo" || "$1" == "odoo-bin" || -z "$1" ]]; then
  exec odoo "${ODOO_ARGS[@]}" -c "${ODOO_RC:-/etc/odoo/odoo.conf}"
else
  exec "$@"
fi