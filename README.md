# Odoo Mailer

Odoo Mailer is a small Docker image that receives inbound SMTP email with Postfix and forwards every message for a configured domain to Odoo through the official `odoo-mailgate.py` script.

It is useful when Odoo runs behind Docker Compose, Kubernetes, or another private network and you want a dedicated SMTP entry point for aliases such as `support@example.com`, `sales@example.com`, or catch-all inbound mail.

## Features

- Receives SMTP traffic on port `25`
- Routes all recipients for one domain to Odoo mailgate
- Uses the official mailgate script from the selected Odoo version
- Supports `linux/amd64` and `linux/arm64` images through GitHub Actions
- Keeps raw email logging disabled by default to avoid leaking message content

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
  ghcr.io/OWNER/REPOSITORY:latest
```

Replace `OWNER/REPOSITORY` with the GitHub repository path where this image is published.

## Docker Compose

```yaml
services:
  odoo-mailer:
    image: ghcr.io/OWNER/REPOSITORY:latest
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
| `LOG_RAW_EMAIL` | No | `false` | Set to `true` to print raw inbound email to container logs for debugging. |

The Odoo mailgate script is downloaded at build time. The default Odoo version is `19.0`; override it when building:

```bash
docker build --build-arg ODOO_VERSION=19.0 -t odoo-mailer .
```

## DNS and networking

Point the MX record for your domain to the host running this container. Port `25` must be reachable from the internet, and the container must be able to reach your Odoo instance on `ODOO_HOST:ODOO_PORT`.

For production usage, put this service behind the normal mail infrastructure protections you require, such as firewall rules, provider-level filtering, monitoring, and backups of your Odoo database.

## Publishing

This repository includes a GitHub Actions workflow that builds and publishes multi-architecture images to GitHub Container Registry:

- `linux/amd64`
- `linux/arm64`

Images are published on pushes to `main`, version tags such as `v1.0.0`, and pull requests are build-tested without publishing.

The published image name is:

```text
ghcr.io/<owner>/<repository>
```

## License

This project is licensed under the [MIT License](LICENSE).
