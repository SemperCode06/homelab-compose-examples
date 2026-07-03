# Docker Compose Examples from My Homelab

This is where I keep cleaned-up Compose examples for containers I run now or have run in the past. I am sharing them because a working example is often more useful than another wall of documentation.

These are templates, not a one-click platform. My network, storage, domains, and threat model will not be the same as yours. I have replaced my values with obvious examples, documented the parts most likely to need attention, and left enough of the original structure to show how I prefer to organize things.

Use what helps, change what does not, and understand a service before exposing it to the internet.

## What's here

| Stack | What I use it for |
| --- | --- |
| [`authentik`](authentik/) | Identity provider and single sign-on |
| [`cloudflared`](cloudflared/) | A connector for a remotely managed Cloudflare Tunnel |
| [`npm-pihole`](npm-pihole/) | Nginx Proxy Manager and Pi-hole on a macvlan network |
| [`qbittorrent-gluetun`](qbittorrent-gluetun/) | qBittorrent with all network traffic routed through Gluetun |
| [`technitium`](technitium/) | Local DNS, recursion, forwarding, and blocking |
| [`traefik`](traefik/) | Reverse proxy, certificates, and Authentik integration |

Each directory has its own README. Read it before starting the stack—especially the networking notes.

## Before you start

You need:

- A Linux host with Docker Engine and the Docker Compose plugin
- Bash for the helper scripts
- `rg` (ripgrep) only when running the repository-wide validation script locally
- Permission to create storage directories, bind ports, and create Docker networks
- Your own credentials, domain names, network ranges, and storage paths

The values under `192.0.2.0/24` and the `example.com` names are documentation examples. They are not values you should deploy.

## Using a template

From the repository root:

```bash
cp STACK/.env.example STACK/.env
```

Edit `STACK/.env`, replacing every `CHANGE_ME`, `REPLACE_WITH`, example domain, address, and path. Then validate and start it:

```bash
./scripts/preflight.sh STACK
docker compose --env-file STACK/.env -f STACK/compose.yml up -d
```

Follow logs during the first start:

```bash
docker compose --env-file STACK/.env -f STACK/compose.yml logs -f
```

Stacks connected to the shared proxy network expect it to exist first. The default name is `frontend`:

```bash
docker network create frontend
```

## Helper scripts

- `scripts/preflight.sh STACK` refuses unchanged secret placeholders and asks Docker Compose to render the selected configuration. It does not start containers.
- `scripts/check-sanitization.sh` performs the fast generic leak checks used by pre-commit and hides matched content from logs.
- `scripts/validate.sh` renders every example and then runs the sanitization checks. GitHub Actions also runs Gitleaks.

## Contributor secret protection

Install the repository's pre-commit hooks once after cloning:

```bash
python3 -m pip install pre-commit
pre-commit install
pre-commit run --all-files
```

The hooks run both the generic template checks and Gitleaks before a commit is created. See [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`SECURITY.md`](SECURITY.md) for the review and incident process.

Local hooks can be bypassed, so GitHub push protection and required CI checks are the enforcement layer for contributors.

## A few ground rules

- Never commit `.env`, certificates, VPN profiles, ACME state, databases, or persistent application data.
- Pin image versions when repeatable upgrades matter to you. Some examples use moving tags because they reflect how I experimented with the service.
- Backup persistent data before upgrading. A Compose file is not a backup.
- Review exposed ports and firewall rules. If you do not need a port from another machine, do not publish it.
- Rotate a credential immediately if it appears in Git history, even if the repository is private.

If you find an error or have a safer, cleaner variation, open an issue or pull request and explain the tradeoff. I am interested in examples that teach people why they work—not just configurations with more lines.
