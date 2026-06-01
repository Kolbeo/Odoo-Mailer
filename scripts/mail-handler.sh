#!/bin/sh
set -eu

mail_file="$(mktemp)"
trap 'rm -f "$mail_file" "${mailgate_output_file:-}"' EXIT

cat > "$mail_file"

raw_log_file="/var/log/odoo-mailer/raw-email.log"
mailgate_log_file="/var/log/odoo-mailer/mailgate.log"

if [ "${LOG_RAW_EMAIL:-false}" = "true" ]; then
  {
    echo "============= NEW EMAIL ============="
    date -u '+Received at: %Y-%m-%dT%H:%M:%SZ'
    sed -n '1,500p' "$mail_file" | cat -v
    echo "====================================="
  } >> "$raw_log_file" 2>/dev/null || true
fi

mailgate_options=""

if [ "${ODOO_DEBUG:-false}" = "true" ]; then
  mailgate_options="$mailgate_options --debug"
fi

if [ "${ODOO_RETRY_STATUS:-true}" = "true" ]; then
  mailgate_options="$mailgate_options --retry-status"
fi

set +e
if [ "${ODOO_DEBUG:-false}" = "true" ]; then
  mailgate_output_file="$(mktemp)"
  {
    echo "============= ODOO MAILGATE ============="
    date -u '+Started at: %Y-%m-%dT%H:%M:%SZ'
    echo "Target: ${ODOO_PROTO}://${ODOO_HOST}:${ODOO_PORT}"
    echo "Database: ${ODOO_DB}"
    echo "User ID: ${ODOO_USERID}"
    echo "Options: ${mailgate_options}"
    python3 /usr/local/bin/odoo-mailgate.py \
      -d "${ODOO_DB}" \
      -u "${ODOO_USERID}" \
      --host "${ODOO_HOST}" \
      --port "${ODOO_PORT}" \
      --proto "${ODOO_PROTO}" \
      $mailgate_options \
      < "$mail_file" > "$mailgate_output_file" 2>&1
    status="$?"
    if [ -s "$mailgate_output_file" ]; then
      echo "Output:"
      cat "$mailgate_output_file"
    else
      echo "Output: no output from odoo-mailgate.py"
    fi
    echo "Exit status: $status"
    echo "========================================="
    exit "$status"
  } >> "$mailgate_log_file" 2>&1
  status="$?"
else
  python3 /usr/local/bin/odoo-mailgate.py \
    -d "${ODOO_DB}" \
    -u "${ODOO_USERID}" \
    --host "${ODOO_HOST}" \
    --port "${ODOO_PORT}" \
    --proto "${ODOO_PROTO}" \
    $mailgate_options \
    < "$mail_file"
  status="$?"
fi
set -e

if [ "$status" -ne 0 ]; then
  echo "ERROR: odoo-mailgate failed with exit status $status" >&2
  exit "$status"
fi
