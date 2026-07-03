# qBittorrent + Gluetun

This is how I keep qBittorrent behind a VPN without configuring the VPN inside qBittorrent. Gluetun owns the network namespace, and qBittorrent shares it.

That last detail is important: qBittorrent cannot quietly fall back to the host network if the VPN container stops, and every qBittorrent port must be published on Gluetun.

## Before you start

- Obtain a WireGuard configuration from your VPN provider.
- Store it outside the repository and set `WIREGUARD_CONFIG` to its absolute path.
- Set `PUID` and `PGID` to the account that should own downloads and configuration files.
- Ensure `DATA_ROOT` has enough free space and is writable by that account.
- Check that `WEBUI_PORT` and `TORRENT_PORT` are free on the Docker host.

## Setup

```bash
cp qbittorrent-gluetun/.env.example qbittorrent-gluetun/.env
# Edit qbittorrent-gluetun/.env
./scripts/preflight.sh qbittorrent-gluetun
docker compose --env-file qbittorrent-gluetun/.env -f qbittorrent-gluetun/compose.yml up -d
```

Open the qBittorrent web interface at `http://DOCKER_HOST:WEBUI_PORT` and change its generated password immediately (the generated password is in qBittorent logs).

## Verify the routing

```bash
docker compose --env-file qbittorrent-gluetun/.env -f qbittorrent-gluetun/compose.yml ps
docker compose --env-file qbittorrent-gluetun/.env -f qbittorrent-gluetun/compose.yml logs --tail 100 gluetun
```

Confirm Gluetun reports a healthy VPN connection before adding downloads. Compare the public address seen from the Gluetun network namespace with the Docker host's public address using a method you trust; they should not match.

## Troubleshooting

- If the web interface is unreachable, check Gluetun first. qBittorrent has no separate network interface in this stack.
- If files are created with the wrong ownership, correct `PUID` and `PGID`; do not solve it by making the download directory world-writable.
- If your provider does not use a standard `wg0.conf`, adapt the Gluetun environment and mount to that provider's supported configuration.
