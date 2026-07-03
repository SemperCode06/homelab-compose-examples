# Traefik

Traefik is the front door for my container services. I prefer file-based dynamic configuration over a pile of container labels because I can see my routers, middleware, and backends in one predictable place.

This example uses Cloudflare DNS for ACME certificates, protects the dashboard and an example application with Authentik, and includes optional Authentik LDAPS passthrough.

## Before you start

- Your domain's DNS must be managed by Cloudflare for this DNS challenge example.
- Create a narrowly scoped Cloudflare API token that can edit DNS for the required zone.
- Point the hostnames in `.env` to this server through your public or internal DNS design.
- Make sure ports 80, 443, and—if used—636 are available.
- Create the external network named by `FRONTEND_NETWORK` and attach proxied containers to it.
- Start Authentik before expecting protected routes to work.

## Setup

```bash
docker network create frontend
cp traefik/.env.example traefik/.env
# Edit traefik/.env
./scripts/preflight.sh traefik
docker compose --env-file traefik/.env -f traefik/compose.yml up -d
```

Follow certificate and provider startup:

```bash
docker compose --env-file traefik/.env -f traefik/compose.yml logs -f
```

The dashboard path is `https://TRAEFIK_DASHBOARD_HOST/dashboard/`. It will not be available if the Authentik forward-auth endpoint is unavailable or not configured for Traefik.

## Dynamic configuration layout

Dynamic configuration is split by responsibility instead of being kept in one large file:

- `config/dynamic/yourdomain.yml` contains HTTP routers for your domain. Rename or copy this file when organizing multiple domains.
- `config/dynamic/services.yml` contains HTTP and TCP backend targets.
- `config/dynamic/middlewares.yml` contains reusable request-processing and authentication middleware.
- `config/dynamic/tcp-routers.yml` contains non-HTTP TCP routing, demonstrated with Authentik LDAPS.

Traefik watches the entire `config/dynamic` directory and reloads these files when they change. Keep router rules in the domain file and reusable implementation details in the other files. Add new environment variables to both `.env` and the Traefik service's `environment` section when using them inside dynamic Go templates.

The wildcard certificate example in `yourdomain.yml` uses `DOMAIN`. Each hostname still has its own variable so the example can be adapted without editing router files.

## Adding another service

1. Attach the application to the shared `frontend` network, or give Traefik a reachable backend URL.
2. Add the backend under `http.services` in `services.yml`.
3. Add its hostname and router under `http.routers` in `yourdomain.yml`.
4. Apply `authentik@file` only if the application should use forward authentication.
5. Add any new template variables to `.env` and `compose.yml`.

Traefik reloads valid dynamic changes without restarting. Check the logs after every edit; a YAML file can parse correctly while still containing an invalid Traefik option.

## Security notes

- The dashboard is an administrative interface. Keep authentication enabled and consider restricting it to trusted networks as well.
- The Cloudflare API token should have only the DNS permissions required for certificate issuance.
- The dynamic directory is mounted read-only. Traefik does not need to modify router configuration.
- This setup intentionally does not mount the Docker socket.
- Remove the LDAPS entry point, router, service, environment values, and port 636 mapping if you do not use it.
