# Nginx Proxy Manager + Pi-hole

I used this combination to put reverse-proxy and DNS services directly on my LAN with stable addresses. Both containers join a macvlan network; Nginx Proxy Manager also joins a normal Docker bridge.

Macvlan is useful here, but it is not beginner-friendly. Plan the addresses before starting the stack and understand how your switch, virtual-machine host, and network interface handle multiple MAC addresses on a single interface (unless you're using a seperate interface on the host).

## Before you start

- The sample `192.0.2.0/24` network is documentation-only. Replace every network value with your LAN details.
- Reserve `NPM_IPV4`, `PIHOLE_IPV4`, and the optional shim address outside your DHCP pool.
- Set `MACVLAN_PARENT` to the host interface connected to that LAN.
- Replace the Pi-hole password and storage path.
- Confirm ports 80, 81, and 443 are not already bound on the Docker host if you use this without macvlan.
- Do not start this beside another service already using port 53 on the same LAN address.

## Setup

```bash
cp npm-pihole/.env.example npm-pihole/.env
# Edit npm-pihole/.env and verify every address
./scripts/preflight.sh npm-pihole
docker compose --env-file npm-pihole/.env -f npm-pihole/compose.yml up -d
```

Open Nginx Proxy Manager at `http://NPM_IPV4:81` and Pi-hole at `http://PIHOLE_IPV4/admin`. Change any application-generated default credentials during initial setup.

Check both containers before changing client DNS:

```bash
docker compose --env-file npm-pihole/.env -f npm-pihole/compose.yml ps
docker compose --env-file npm-pihole/.env -f npm-pihole/compose.yml logs --tail 100
```

Point one test client at Pi-hole first. Move the whole network only after normal lookups, local names, and upstream resolution work as expected.

## Single-interface host routes

Linux does not allow a macvlan parent interface to communicate directly with its macvlan children. If the Docker host has one physical interface and must reach Nginx Proxy Manager or Pi-hole, create a macvlan shim on that same interface and add a host route for each container.

The following example corresponds to the fake values in `.env.example`. Replace `eth0` and every `192.0.2.x` address with unused addresses from your LAN before running it:

```bash
sudo ip link add macvlan-shim link eth0 type macvlan mode bridge
sudo ip addr add 192.0.2.48/32 dev macvlan-shim
sudo ip link set macvlan-shim up
sudo ip route add 192.0.2.49/32 dev macvlan-shim  # Pi-hole
sudo ip route add 192.0.2.50/32 dev macvlan-shim  # NPM
```

Use an unused address for the shim itself; it must differ from the host, gateway, and container addresses. Keep the routes at `/32`: routing the entire LAN subnet through the shim can replace or conflict with the host's normal route through `eth0`.

Verify connectivity from the Docker host:

```bash
ping -c 1 192.0.2.49
ping -c 1 192.0.2.50
```

The `ip` commands are temporary and disappear after reboot. Recreate the shim and routes using your host's network manager (`systemd-networkd`, NetworkManager, or the distribution's interface configuration) once the addresses are confirmed working.

To remove the temporary setup:

```bash
sudo ip route del 192.0.2.49/32 dev macvlan-shim
sudo ip route del 192.0.2.50/32 dev macvlan-shim
sudo ip link del macvlan-shim
```

## Things worth knowing

- The host-shim routes solve host-to-container communication; other LAN clients should reach the macvlan addresses directly.
- Some Wi-Fi adapters and managed virtual switches reject multiple MAC addresses behind one interface. In that environment, macvlan may be the wrong design.
- If Pi-hole becomes the LAN's only DNS server, its downtime affects every client. Keep a recovery plan that does not depend on DNS or deploy a secondary DNS server.
- Backup the NPM and Pi-hole directories under `DATA_ROOT` before upgrades.
