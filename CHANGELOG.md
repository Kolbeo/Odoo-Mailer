# Changelog

All notable changes to this project will be documented in this file.

## v1.1.0

### Added

- Added a GitHub Actions workflow to build and publish multi-architecture Docker images to GitHub Container Registry.
- Added support for `linux/amd64` and `linux/arm64` image builds.
- Added an MIT license.
- Added a professional English README with Docker, Docker Compose, configuration, DNS, troubleshooting, publishing, and license sections.
- Added `ODOO_PROTO` to support both HTTP and HTTPS Odoo endpoints.
- Added `ODOO_DEBUG` to expose Odoo mailgate debug output in Docker logs.
- Added `ODOO_RETRY_STATUS` to return temporary failure status when Odoo cannot be reached.
- Added `LOG_RAW_EMAIL` for capped raw inbound email previews during debugging.
- Added a Docker healthcheck for the Postfix service.
- Added separate runtime scripts:
  - `scripts/mail-handler.sh`
  - `scripts/docker-entrypoint.sh`

### Changed

- Reworked the Dockerfile to follow cleaner Dockerfile practices and remove duplicated content.
- Moved embedded shell scripts out of the Dockerfile for easier review and maintenance.
- Switched the Odoo mailgate download from a moving Odoo version branch to a pinned Odoo commit through `ODOO_REF`.
- Updated image examples to use `ghcr.io/cocochristmas/odoo-mailer`.
- Changed raw email debug logging so it no longer writes to the Postfix pipe command output.
- Changed debug logs to use `/var/log/odoo-mailer/raw-email.log` and `/var/log/odoo-mailer/mailgate.log`.
- Made the Postfix healthcheck silent to avoid repeated status messages in Docker logs.
- Patched `odoo-mailgate.py` at build time so `ODOO_PASSWORD` is read from the environment instead of being passed as a command-line argument.
- Kept raw email logging disabled by default to reduce the risk of leaking message contents.

### Fixed

- Fixed Postfix pipe failures caused by dumping raw email content to standard output.
- Fixed missing Docker log visibility for raw email debugging by forwarding dedicated log files with `tail -F`.
- Fixed missing Docker log visibility for Odoo mailgate debug output when `ODOO_DEBUG=true`.
- Fixed noisy recurring healthcheck logs from `postfix status`.
- Fixed README placeholders by replacing generic image names with the `cocochristmas/odoo-mailer` GHCR image path.

### Security

- Avoided passing `ODOO_PASSWORD` as a visible process command-line argument.
- Replaced world-writable temporary debug log files with dedicated log files under `/var/log/odoo-mailer`.
- Restricted debug log file ownership and permissions to the Postfix delivery user.
- Documented that raw email logging should remain disabled in production.

## v1.0.0

Initial stable release of Odoo Mailer.

### Features

- Docker image based on Debian Bookworm Slim
- Postfix SMTP gateway for inbound email processing
- Catch-all routing for a configured domain
- Forwarding to Odoo through the official `odoo-mailgate.py` script
- Configurable Odoo connection settings through environment variables
- Raw email logging disabled by default, with optional debug mode
- Multi-architecture image publishing for:
  - `linux/amd64`
  - `linux/arm64`
- GitHub Actions workflow for automated builds and GHCR publishing
- MIT License
- Complete English README with Docker and Docker Compose usage

### Docker image

```text
ghcr.io/cocochristmas/odoo-mailer:1.0.0
ghcr.io/cocochristmas/odoo-mailer:latest
```

### Notes

This release is intended for deployments that need a lightweight SMTP entry point to receive mail and forward it to an Odoo instance
using Odoo mailgate.
