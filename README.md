# Odoo Mailer

Odoo Mailer is a small Docker image that receives inbound SMTP email with Postfix and forwards every message for a configured domain to Odoo through the official `odoo-mailgate.py` script.

It is useful when Odoo runs behind Docker Compose, Kubernetes, or another private network and you want a dedicated SMTP entry point for aliases such as `support@example.com`, `sales@example.com`, or catch-all inbound mail.

## Features

- Receives SMTP traffic on port `25`
- Routes all recipients for one domain to Odoo mailgate
- Uses the official Odoo mailgate script pinned to a reproducible Odoo commit
- Supports `linux/amd64` and `linux/arm64` images through GitHub Actions
- Keeps raw email logging disabled by default to avoid leaking message content
- Includes a Docker healthcheck for the Postfix service

## Quick start

```bash
docker run --rm \
  -p 25:25 \
  -e DOMAIN=example.com \
  -e ODOO_DB=my_odoo_database \
  -e ODOO_USERID=1 \
  -e ODOO_PASSWORD=change-me \
  -e ODOO_HOST=odoo \
  -e ODOO_PORT=8069 \
  -e ODOO_PROTO=http \
  ghcr.io/kolbeo/odoo-mailer:latest
```

The image is published from the `kolbeo/odoo-mailer` GitHub repository.

## Docker Compose

```yaml
services:
  odoo-mailer:
    image: ghcr.io/kolbeo/odoo-mailer:latest
    restart: unless-stopped
    ports:
      - "25:25"
    environment:
      DOMAIN: example.com
      ODOO_DB: my_odoo_database
      ODOO_USERID: "1"
      ODOO_PASSWORD: change-me
      ODOO_HOST: odoo
      ODOO_PORT: "8069"
      ODOO_PROTO: http
```

## Configuration

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `DOMAIN` | Yes | empty | Domain accepted by Postfix. All recipients for this domain are forwarded to Odoo. |
| `ODOO_DB` | Yes | empty | Odoo database name. |
| `ODOO_USERID` | Yes | empty | Odoo user ID used by `odoo-mailgate.py`. |
| `ODOO_PASSWORD` | Yes | empty | Password or API key for the configured Odoo user. |
| `ODOO_HOST` | No | `odoo` | Odoo host reachable from the container. |
| `ODOO_PORT` | No | `8069` | Odoo HTTP port. |
| `ODOO_PROTO` | No | `http` | Protocol used to reach Odoo. Use `https` if Odoo is exposed through TLS. |
| `ODOO_DEBUG` | No | `false` | Set to `true` to include Odoo mailgate debug output in container logs through `/var/log/odoo-mailer/mailgate.log`. |
| `ODOO_RETRY_STATUS` | No | `true` | Return a temporary failure status when Odoo cannot be reached, so the sender can retry. |
| `LOG_RAW_EMAIL` | No | `false` | Set to `true` to print a capped raw inbound email preview to container logs through `/var/log/odoo-mailer/raw-email.log`. |

The Odoo mailgate script is downloaded at build time from a pinned Odoo commit. Override `ODOO_REF` only when you intentionally want to rebuild against another Odoo commit, branch, or tag:

```bash
docker build --build-arg ODOO_REF=616e82d7b3a53b1facf481e783baed3e99393d3c -t odoo-mailer .
```

The handler does not pass `ODOO_PASSWORD` as a command-line argument. The image patches `odoo-mailgate.py` at build time so the password is read from the `ODOO_PASSWORD` environment variable instead.

## DNS and networking

Point the MX record for your domain to the host running this container. Port `25` must be reachable from the internet, and the container must be able to reach your Odoo instance on `ODOO_HOST:ODOO_PORT`.

The `DOMAIN` value must match the recipient domain handled by this container. For example, if inbound email is addressed to `catchall@mail.example.com`, set `DOMAIN=mail.example.com`.

For production usage, put this service behind the normal mail infrastructure protections you require, such as firewall rules, provider-level filtering, monitoring, and backups of your Odoo database.

## Troubleshooting

If Postfix logs `Command died with status ...: "/usr/local/bin/mail-handler.sh"`, the email was accepted by Postfix but Odoo mailgate failed while processing it.

Common causes are:

- `ODOO_HOST`, `ODOO_PORT`, or `ODOO_PROTO` does not point to a reachable Odoo instance
- `ODOO_DB` does not match the Odoo database name
- `ODOO_USERID` or `ODOO_PASSWORD` is invalid
- Odoo has no matching mail alias or alias domain for the recipient address

Set `ODOO_DEBUG=true` temporarily to get more details from `odoo-mailgate.py` in Docker logs. Keep `LOG_RAW_EMAIL=false` in production because raw email logs can expose private message content.

## Publishing

This repository includes a GitHub Actions workflow that builds and publishes multi-architecture images to GitHub Container Registry:

- `linux/amd64`
- `linux/arm64`

Images are published on pushes to `main`, version tags such as `v1.0.0`, and pull requests are build-tested without publishing.

The published image name is:

```text
ghcr.io/kolbeo/odoo-mailer
```

## License

This project is licensed under the [MIT License](LICENSE).
