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

install -d -m 750 -o nobody -g nogroup /var/log/odoo-mailer
touch /var/log/odoo-mailer/raw-email.log /var/log/odoo-mailer/mailgate.log
chown nobody:nogroup /var/log/odoo-mailer/raw-email.log /var/log/odoo-mailer/mailgate.log
chmod 660 /var/log/odoo-mailer/raw-email.log /var/log/odoo-mailer/mailgate.log

if [ "${LOG_RAW_EMAIL:-false}" = "true" ]; then
  tail -F /var/log/odoo-mailer/raw-email.log &
fi

if [ "${ODOO_DEBUG:-false}" = "true" ]; then
  tail -F /var/log/odoo-mailer/mailgate.log &
fi

printf '%s\n' "$DOMAIN" > /etc/mailname
printf '@%s    handler@localhost\n' "$DOMAIN" > /etc/postfix/virtual

postconf -e "myhostname = ${DOMAIN}"
postconf -e "myorigin = ${DOMAIN}"
postconf -e "mydestination = localhost"
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = ipv4"
postconf -e "virtual_alias_domains = ${DOMAIN}"
postconf -e "virtual_alias_maps = hash:/etc/postfix/virtual"
postconf -e "alias_maps = hash:/etc/aliases"
postconf -e "alias_database = hash:/etc/aliases"
postconf -e "local_recipient_maps = proxy:unix:passwd.byname \$alias_maps"
postconf -e "import_environment = ODOO_DB ODOO_USERID ODOO_PASSWORD ODOO_HOST ODOO_PORT ODOO_PROTO ODOO_DEBUG ODOO_RETRY_STATUS DOMAIN LOG_RAW_EMAIL"
postconf -e "export_environment = ODOO_DB ODOO_USERID ODOO_PASSWORD ODOO_HOST ODOO_PORT ODOO_PROTO ODOO_DEBUG ODOO_RETRY_STATUS DOMAIN LOG_RAW_EMAIL"
postconf -e "maillog_file = /dev/stdout"

postmap /etc/postfix/virtual
newaliases

exec postfix start-fg
