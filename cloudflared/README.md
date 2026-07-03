# Cloudflared

This is the small version of my Cloudflare Tunnel setup: one connector, one token, and no host ports. The tunnel routes themselves are managed from Cloudflare rather than this Compose file. Makes for a pretty simple setup

## Setup

Create a remotely managed tunnel in your Cloudflare account and obtain its connector token. Then, from the repository root:

```bash
cp cloudflared/.env.example cloudflared/.env
# Replace the fake TUNNEL_TOKEN in cloudflared/.env
./scripts/preflight.sh cloudflared
docker compose --env-file cloudflared/.env -f cloudflared/compose.yml up -d
```

## Verify

```bash
docker compose --env-file cloudflared/.env -f cloudflared/compose.yml ps
docker compose --env-file cloudflared/.env -f cloudflared/compose.yml logs --tail 100
```

The connector should remain running and report successful tunnel connections. Confirm each public hostname separately; a connected tunnel does not guarantee that its origin service or route is correct.

## Security notes

- The tunnel token is a credential. Keep `.env` out of Git and restrict who can read it.
- Rotate any token that has appeared in a Compose file, terminal transcript, issue, or Git history.
- A tunnel avoids inbound port forwarding, but it does not replace authentication or careful Cloudflare access policies.
