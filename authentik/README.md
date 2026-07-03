# Authentik

I use Authentik as the identity layer in front of services that do not provide the access controls I want on their own. This example runs the server, worker, and PostgreSQL together and connects the server to the shared Traefik network.

## Before you start

- Create the external `frontend` network, or change `FRONTEND_NETWORK` to an existing proxy network.
- Create the directory selected by `DATA_ROOT` and make sure Docker can write to it.
- Generate unique values for `PG_PASS` and `AUTHENTIK_SECRET_KEY`. Do not reuse either value elsewhere.
- Start Traefik as well if you use this example unchanged; Authentik does not publish a host port here.

## Setup

From the repository root:

```bash
docker network create frontend
cp authentik/.env.example authentik/.env
# Edit authentik/.env
./scripts/preflight.sh authentik
docker compose --env-file authentik/.env -f authentik/compose.yml up -d
```

Watch the initial migration and startup:

```bash
docker compose --env-file authentik/.env -f authentik/compose.yml logs -f server worker
```

With the accompanying Traefik example, browse to the value configured as `AUTHENTIK_HOST` in Traefik.

## Notes from my setup

- PostgreSQL uses a named Docker volume; `DATA_ROOT` holds Authentik's application data and custom templates.
- The worker mounts `/var/run/docker.sock` so Authentik can manage Docker outposts. That mount gives the container significant control over the host. Remove it if you do not use managed outposts.
- Keep PostgreSQL on the default private network or a private backend network of your own. Only the Authentik server joins `frontend`.
- Backup the database, application data, and secret key together. The Compose file alone cannot restore an Authentik installation.

## Verify

```bash
docker compose --env-file authentik/.env -f authentik/compose.yml ps
docker compose --env-file authentik/.env -f authentik/compose.yml logs --tail 100 server
```

PostgreSQL should report healthy and both Authentik containers should remain running.
