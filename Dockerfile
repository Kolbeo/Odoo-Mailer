# syntax=docker/dockerfile:1

FROM debian:bookworm-slim

ARG ODOO_VERSION=19.0

LABEL org.opencontainers.image.title="Odoo Mailer" \
      org.opencontainers.image.description="Postfix mail gateway that forwards incoming email to Odoo mailgate."

ENV DEBIAN_FRONTEND=noninteractive \
    DOMAIN="" \
    ODOO_DB="" \
    ODOO_USERID="" \
    ODOO_PASSWORD="" \
    ODOO_HOST="odoo" \
    ODOO_PORT="8069" \
    ODOO_VERSION="${ODOO_VERSION}" \
    LOG_RAW_EMAIL="false"

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        postfix \
        python3 \
    && curl -fsSL \
        -o /usr/local/bin/odoo-mailgate.py \
        "https://raw.githubusercontent.com/odoo/odoo/${ODOO_VERSION}/addons/mail/static/scripts/odoo-mailgate.py" \
    && chmod +x /usr/local/bin/odoo-mailgate.py \
    && rm -rf /var/lib/apt/lists/*

RUN cat > /usr/local/bin/mail-handler.sh <<'EOF' \
    && chmod +x /usr/local/bin/mail-handler.sh
#!/bin/sh
set -eu

mail_file="$(mktemp)"
trap 'rm -f "$mail_file"' EXIT

cat > "$mail_file"

if [ "${LOG_RAW_EMAIL:-false}" = "true" ]; then
  echo "============= NEW EMAIL ============="
  cat "$mail_file"
  echo "====================================="
fi

python3 /usr/local/bin/odoo-mailgate.py \
  -d "${ODOO_DB}" \
  -u "${ODOO_USERID}" \
  -p "${ODOO_PASSWORD}" \
  --host "${ODOO_HOST}" \
  --port "${ODOO_PORT}" \
  < "$mail_file"
EOF

RUN printf '%s\n' 'handler: "|/usr/local/bin/mail-handler.sh"' >> /etc/aliases \
    && newaliases

RUN cat > /usr/local/bin/docker-entrypoint.sh <<'EOF' \
    && chmod +x /usr/local/bin/docker-entrypoint.sh
#!/bin/sh
set -eu

required_vars="DOMAIN ODOO_DB ODOO_USERID ODOO_PASSWORD"

for var_name in $required_vars; do
  eval "var_value=\${$var_name:-}"
  if [ -z "$var_value" ]; then
    echo "ERROR: $var_name environment variable is required" >&2
    exit 1
  fi
done

printf '%s\n' "$DOMAIN" > /etc/mailname
printf '@%s    handler@localhost\n' "$DOMAIN" > /etc/postfix/virtual

postconf -e "myhostname = mail.${DOMAIN}"
postconf -e "myorigin = ${DOMAIN}"
postconf -e "mydestination = localhost"
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = ipv4"
postconf -e "virtual_alias_domains = ${DOMAIN}"
postconf -e "virtual_alias_maps = hash:/etc/postfix/virtual"
postconf -e "alias_maps = hash:/etc/aliases"
postconf -e "alias_database = hash:/etc/aliases"
postconf -e "local_recipient_maps = proxy:unix:passwd.byname \$alias_maps"
postconf -e "import_environment = ODOO_DB ODOO_USERID ODOO_PASSWORD ODOO_HOST ODOO_PORT DOMAIN LOG_RAW_EMAIL"
postconf -e "export_environment = ODOO_DB ODOO_USERID ODOO_PASSWORD ODOO_HOST ODOO_PORT DOMAIN LOG_RAW_EMAIL"
postconf -e "maillog_file = /dev/stdout"

postmap /etc/postfix/virtual
newaliases

exec postfix start-fg
EOF

EXPOSE 25

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
