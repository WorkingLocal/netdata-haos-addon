# Netdata Agent — Home Assistant OS Add-on

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Home Assistant](https://img.shields.io/badge/Home%20Assistant-Add--on-blue)](https://www.home-assistant.io/addons/)

A [Home Assistant OS](https://www.home-assistant.io/installation/odroid-n2/#install-home-assistant-operating-system) add-on that runs a [Netdata](https://www.netdata.cloud/) monitoring agent on your Home Assistant host.

It exposes a real-time dashboard of your HA host's performance metrics — CPU, RAM, disk, network, system load — and optionally streams those metrics to a self-hosted Netdata parent node.

---

## Features

- **Real-time metrics** for the Home Assistant host (CPU, RAM, disk I/O, network, system load)
- **Streaming support** — acts as a child node and forwards metrics to any Netdata parent
- **Zero cloud dependency** — fully self-hosted, no Netdata Cloud account required
- **Local dashboard** available at `http://<ha-ip>:19999`
- **amd64 and aarch64** support (Intel NUC, Raspberry Pi 5, and similar)

---

## Installation

### Step 1 — Add this repository to Home Assistant

In your Home Assistant UI:

1. Go to **Settings → Add-ons → Add-on Store**
2. Click the **⋮ menu** (top right) → **Repositories**
3. Add the following URL:

    ```
    https://github.com/WorkingLocal/netdata-haos-addon
    ```

4. Click **Add**, then **Close**

### Step 2 — Install the add-on

After the store refreshes, find **Netdata Agent** and click **Install**.  
The first install builds the Docker image — this takes 2–5 minutes.

### Step 3 — Configure

Go to the **Configuration** tab and set your options:

```yaml
hostname: my-home-assistant    # How this node appears in dashboards
streaming_enabled: false       # Set true to stream to a parent node
parent_url: ""                 # e.g. 192.168.1.10:19999
api_key: ""                    # UUID — generate with: python3 -c "import uuid; print(uuid.uuid4())"
```

See [DOCS.md](netdata-agent/DOCS.md) for full configuration details.

### Step 4 — Start

Click **Start** on the Info tab. The local dashboard is available at:

```
http://<your-ha-ip>:19999
```

---

## Streaming to a Netdata Parent

This add-on can forward all metrics to a central Netdata instance (e.g., running on a VPS or home server). This lets you view all your nodes — including Home Assistant — in one place.

### Quick setup

**1. Generate an API key** (run this anywhere with Python):
```bash
python3 -c "import uuid; print(uuid.uuid4())"
```

**2. On the Netdata parent**, add to `/etc/netdata/stream.conf`:
```ini
[<your-uuid>]
    enabled = yes
    allow from = *
    default memory mode = dbengine
    health enabled by default = auto
```
Then restart Netdata on the parent.

**3. In this add-on**, configure:
```yaml
streaming_enabled: true
parent_url: "192.168.1.10:19999"   # your parent's IP and port
api_key: "<your-uuid>"
```

**4. Restart the add-on.** The HAOS node appears as a child on the parent's dashboard within seconds.

> **Tip:** If you use Tailscale, set `parent_url` to the parent's Tailscale IP for a secure, encrypted connection without opening firewall ports.

---

## What metrics are collected?

Because the add-on runs with `host_network` and `host_pid` access, Netdata can see the actual Home Assistant host hardware:

| Category | Metrics |
|----------|---------|
| **CPU** | Usage per core, frequency, interrupts, softirqs |
| **Memory** | Used, free, cached, swap |
| **Disk** | I/O throughput, operations, latency, space usage per mount |
| **Network** | Bandwidth, packets, errors per interface |
| **System** | Load average, context switches, processes, forks |
| **Temperature** | CPU and NVMe temperatures (if sensors are available) |

---

## Requirements

| Requirement | Details |
|-------------|---------|
| Home Assistant OS | 2023.x or later (Supervised also works) |
| Architecture | amd64 or aarch64 |
| Port | 19999/TCP (for local dashboard) |
| Internet | Required during install to pull the Netdata Docker image |

---

## Troubleshooting

**Add-on fails to start**  
Check the add-on logs. If you see `ERROR: streaming_enabled is true but parent_url or api_key is empty`, fill in both fields or set `streaming_enabled: false`.

**Local dashboard not reachable**  
Make sure port 19999 is not blocked by your network or firewall. Access it via `http://<ha-ip>:19999` (not HTTPS).

**Streaming not working**  
- Verify the parent node's `stream.conf` has the correct UUID and `enabled = yes`
- Check that the parent's port 19999 is reachable from the HAOS host
- Look at the add-on logs for connection errors

**High memory usage warning**  
Netdata on low-RAM devices (e.g., Raspberry Pi 4 with 2 GB) may trigger memory alerts. This is usually harmless — most of the "used" memory is Linux page cache, not actual application memory.

---

## License

MIT — see [LICENSE](LICENSE)

---

## Credits

Built on top of the official [Netdata Docker image](https://hub.docker.com/r/netdata/netdata).  
Home Assistant add-on structure follows the [official add-on development guide](https://developers.home-assistant.io/docs/add-ons/).
