# Technitium DNS

I have used Technitium as the DNS service for local clients, with recursion restricted to private networks, blocking enabled, and HTTPS forwarding configured upstream. This template keeps its configuration and logs in Docker volumes.

## Before you start

- Make sure TCP and UDP port 53 are not already used by another resolver on the host.
- Replace `DNS_HOSTNAME`, `DNS_DOMAIN`, and `DNS_ADMIN_PASSWORD`.
- Review the selected forwarder. The sample uses a public DNS-over-HTTPS endpoint.
- Decide which client networks should be allowed to recurse. The example relies on Technitium's private-network policy.

## Setup

```bash
cp technitium/.env.example technitium/.env
# Edit technitium/.env
./scripts/preflight.sh technitium
docker compose --env-file technitium/.env -f technitium/compose.yml up -d
```

Open the web console at `http://DOCKER_HOST:DNS_HTTP_PORT` and confirm the configured hostname, forwarders, recursion policy, and block lists before pointing clients at it.

## Verify

Query the server directly from another machine, replacing the example address:

```bash
dig @DNS_SERVER_IP example.org
```

Then inspect the service:

```bash
docker compose --env-file technitium/.env -f technitium/compose.yml ps
docker compose --env-file technitium/.env -f technitium/compose.yml logs --tail 100
```

## HTTPS and DHCP

The Compose file maps `DNS_HTTPS_PORT`, but a port mapping alone does not enable HTTPS in Technitium. Configure a certificate and enable the HTTPS web service in Technitium before relying on that port. You can also setup DNS over HTTP and put Technitium behind a reverse-proxy to serve DoH that way.

DHCP is deliberately not enabled. DHCP deployments generally need UDP port 67, access to the local broadcast network, and often host networking. Review the network impact before changing this template; running two DHCP servers on one LAN will cause real problems.

Backup the `config` volume before upgrades. It contains the useful part of the installation.
