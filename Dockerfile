# syntax=docker/dockerfile:1

FROM debian:bookworm-slim

ARG ODOO_REF=616e82d7b3a53b1facf481e783baed3e99393d3c

LABEL org.opencontainers.image.title="Odoo Mailer" \
      org.opencontainers.image.description="Postfix mail gateway that forwards incoming email to Odoo mailgate."

ENV DEBIAN_FRONTEND=noninteractive \
    DOMAIN="" \
    ODOO_DB="" \
    ODOO_USERID="" \
    ODOO_PASSWORD="" \
    ODOO_HOST="odoo" \
    ODOO_PORT="8069" \
    ODOO_PROTO="http" \
    ODOO_DEBUG="false" \
    ODOO_RETRY_STATUS="true" \
    ODOO_REF="${ODOO_REF}" \
    LOG_RAW_EMAIL="false"

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        postfix \
        python3 \
    && curl -fsSL \
        -o /usr/local/bin/odoo-mailgate.py \
        "https://raw.githubusercontent.com/odoo/odoo/${ODOO_REF}/addons/mail/static/scripts/odoo-mailgate.py" \
    && sed -i "s/import socket/import socket\\n    import os/" /usr/local/bin/odoo-mailgate.py \
    && sed -i "s/default='admin'/default=os.environ.get('ODOO_PASSWORD', 'admin')/" /usr/local/bin/odoo-mailgate.py \
    && chmod +x /usr/local/bin/odoo-mailgate.py \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 scripts/mail-handler.sh /usr/local/bin/mail-handler.sh
COPY --chmod=755 scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN printf '%s\n' 'handler: "|/usr/local/bin/mail-handler.sh"' >> /etc/aliases \
    && newaliases

EXPOSE 25

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD postfix status >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
