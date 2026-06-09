# VLESS + Reality VPN Tunnel

![Static Badge](https://img.shields.io/badge/protocol-VLESS-blue) ![Static Badge](https://img.shields.io/badge/security-Reality-green) ![Static Badge](https://img.shields.io/badge/xray-26.3.27-red)

Xray-based VLESS + Reality tunnel packaged in Docker. Portable to any VPS. Client connects via SOCKS5/HTTP proxy or TUN mode (full VPN).

---

## Table of Contents

- [Architecture](#architecture)
- [Quick Start (Server)](#quick-start-server)
- [Configuration Reference](#configuration-reference)
- [Client Setup](#client-setup)
- [Full VPN with TUN Mode](#full-vpn-with-tun-mode)
- [Troubleshooting](#troubleshooting)
- [Security Notes](#security-notes)

---

## Architecture

```
┌─────────────────┐     Reality / TLS      ┌──────────────────┐
│   Client         │ ◄──────────────────►  │   Server (VPS)   │
│  (v2rayN/Neko/   │    port 443           │   Docker:xray    │
│   Sing-box)      │                       │   VLESS+Reality  │
│                  │                       │   outbound→internet
└─────────────────┘                       └──────────────────┘
        │
   SOCKS5 :10808
   HTTP   :10809
        │
   Browser / Apps
```

VLESS + Reality encrypts traffic while appearing as a normal TLS connection to `www.microsoft.com`, making it undetectable to DPI.

---

## Quick Start (Server)

### Prerequisites

- Linux VPS (Ubuntu/Debian/CentOS/Alpine)
- Docker & Docker Compose installed
- Port 443 open (or change port in config)
- Domain not required (uses `www.microsoft.com` as SNI)

### 1. Get the Files

```bash
git clone https://github.com/kukuliketik/ls-vless-conn.git /opt/vless
cd /opt/vless
```

### 2. Generate Unique Keys

Each deployment must have its own keys. Run once:

```bash
# Using script (requires xray or Docker):
bash gen-keys.sh

# Or manually with Docker:
UUID=$(sudo docker run --rm vless-xray xray uuid)
KEY_PAIR=$(sudo docker run --rm vless-xray xray x25519)
PRIVATE_KEY=$(echo "$KEY_PAIR" | grep 'PrivateKey' | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEY_PAIR" | grep 'Password' | awk '{print $2}')
SHORT_ID=$(openssl rand -hex 8)

echo "UUID=$UUID"
echo "PrivateKey=$PRIVATE_KEY"
echo "PublicKey=$PUBLIC_KEY"
echo "ShortId=$SHORT_ID"
```

### 3. Configure

All values are stored in `.env`. Edit it with your generated keys:

```bash
# .env — edit with your values
UUID=<your-uuid>
PRIVATE_KEY=<your-private-key>
PUBLIC_KEY=<your-public-key>
SHORT_ID=<your-short-id>
```

### 4. Build & Run

```bash
sudo docker compose up -d --build
```

### 5. Verify

```bash
# Check container status
sudo docker ps --filter name=vless-reality

# Check logs
sudo docker logs vless-reality

# Test Reality handshake
openssl s_client -connect YOUR_SERVER_IP:443 \
  -servername www.microsoft.com 2>&1 | grep "CONNECTED"
```

Expected output:

```
Xray 26.3.27 started       ← container logs
CONNECTED(00000003)         ← TLS handshake success
```

---

### Field Reference

For each new deployment, all of these must be regenerated (never reuse keys across VPS):

| Field | Where to get | Example |
|---|---|---|
| **Server IP** (`Address`) | Your VPS public IP | `203.0.113.1` |
| **Port** | Any open port (default `443`) | `443` |
| **UUID** | `xray uuid` | `aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee` |
| **PrivateKey** | `xray x25519` → `PrivateKey:` | `AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` |
| **PublicKey** | `xray x25519` → `Password (PublicKey):` | `BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB` |
| **ShortId** | `openssl rand -hex 8` | `0123456789abcdef` |
| **SNI** | Any popular TLS site | `www.microsoft.com` |
| **Fingerprint** | TLS fingerprint to mimic | `chrome` |
| **Flow** | Flow control | `xtls-rprx-vision` |
| **Network** | Transport protocol | `tcp` |
| **Security** | Must be `reality` | `reality` |

> **PrivateKey** stays on the server (in `.env`). **PublicKey** goes to the client. Never share PrivateKey.

---

## Configuration Reference

| Field | Description | Default |
|---|---|---|
| `port` | Listening port | `443` |
| `id` | Client UUID (v4) | generated |
| `flow` | Flow control | `xtls-rprx-vision` |
| `dest` | Fallback target for probe | `www.microsoft.com:443` |
| `serverNames` | Allowed SNI values | `["www.microsoft.com"]` |
| `privateKey` | Reality private key | generated |
| `shortIds` | Short ID for client-auth | `["XXXXXXXX"]` |
| `fingerprint` | TLS fingerprint | `chrome` (implicit) |

### Port Mapping

The container uses `network_mode: host` for performance. To use bridge mode instead:

```yaml
# docker-compose.yml
services:
  xray:
    build: .
    ports:
      - "443:443"
    # remove network_mode: host
```

> **Note:** Bridge mode may have minor performance overhead. Host mode is recommended.

---

## Client Setup

### Method 1: Share Link (v2rayN / Nekobox / v2rayNG)

```
vless://YOUR_UUID@YOUR_SERVER_IP:443?security=reality&encryption=none&pbk=YOUR_PUBLIC_KEY&headerType=none&type=tcp&flow=xtls-rprx-vision&sni=www.microsoft.com&fp=chrome&sid=YOUR_SHORT_ID#VLESS-Reality-VPN
```

Replace `YOUR_UUID`, `YOUR_SERVER_IP`, `YOUR_PUBLIC_KEY`, `YOUR_SHORT_ID` with your values.

Share link generator:

```bash
# Run gen-keys.sh which outputs the full link
bash gen-keys.sh
```

### Method 2: Manual Setup

| Field | Value |
|---|---|
| Protocol | **VLESS** |
| Address | `YOUR_SERVER_IP` |
| Port | `443` |
| UUID | generated UUID |
| Flow | `xtls-rprx-vision` |
| Encryption | `none` |
| Network | `tcp` |
| Security | **Reality** |
| SNI | `www.microsoft.com` |
| Fingerprint | `chrome` |
| PublicKey | generated PublicKey |
| ShortId | generated ShortId |

### Method 3: Local xray Client (SOCKS5/HTTP Proxy)

Use the included `client-config.json` with a local xray instance:

```bash
# Install xray locally, then:
xray run -c client-config.json

# Use as:
# - SOCKS5 proxy: 127.0.0.1:10808
# - HTTP proxy:   127.0.0.1:10809
```

Edit `client-config.json` and replace:

- `__YOUR_SERVER_IP__` — your VPS IP
- `__YOUR_UUID__` — the UUID
- `__YOUR_PUBLIC_KEY__` — the PublicKey
- `__YOUR_SHORT_ID__` — the ShortId

---

## Full VPN with TUN Mode

For true VPN-style routing (all system traffic), use **Sing-box** or **Nekoray** on the client.

### Sing-box TUN Config

```json
{
  "inbounds": [{
    "type": "tun",
    "interface_name": "tun0",
    "inet4_address": "198.18.0.1/15",
    "auto_route": true,
    "strict_route": false
  }],
  "outbounds": [{
    "type": "vless",
    "server": "YOUR_SERVER_IP",
    "server_port": 443,
    "uuid": "YOUR_UUID",
    "flow": "xtls-rprx-vision",
    "tls": {
      "enabled": true,
      "server_name": "www.microsoft.com",
      "utls": {
        "enabled": true,
        "fingerprint": "chrome"
      },
      "reality": {
        "enabled": true,
        "public_key": "YOUR_PUBLIC_KEY",
        "short_id": "YOUR_SHORT_ID"
      }
    }
  }]
}
```

---

## Troubleshooting

### Container won't start

```bash
# Check logs
sudo docker logs vless-reality

# Common issues:
# - "bind: address already in use" → another service on port 443
# - "invalid privateKey" → key has invalid characters, regenerate
# - "failed to open geoip.dat" → rebuild image (geo files missing)
```

### Connection refused

- Check firewall: `sudo iptables -L -n | grep 443`
- Check VPS provider firewall (AWS SG, OVH, etc.)
- Verify port is open: `nc -zv YOUR_IP 443`

### Reality handshake fails

- Ensure `serverNames` includes the SNI the client sends
- Ensure `privateKey` matches `publicKey` (they are a pair)
- Check `shortId` matches between server and client

### Slow speeds

- Use `xtls-rprx-vision` flow (UDP offload)
- Use `network_mode: host` in Docker (skip NAT)
- Check VPS bandwidth cap

---

## Security Notes

| Concern | Mitigation |
|---|---|
| Key compromise | Regenerate keys with `gen-keys.sh` |
| Traffic pattern | Reality mimics TLS 1.3 to Microsoft |
| VPS compromise | Container isolation limits blast radius |
| Logging | `loglevel: warning` — minimal logs |

> **Warning:** Never share your `privateKey`. The `publicKey` is safe to share (it's in the client config).

---

## Files

```
vless/
├── Dockerfile           # Image build: Alpine + xray + geo
├── docker-compose.yml   # Orchestration
├── config.json          # Server config (placeholder keys)
├── client-config.json   # Client local proxy config
├── gen-keys.sh          # Key generator script
└── README.md            # This file
```
