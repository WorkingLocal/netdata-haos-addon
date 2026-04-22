# Netdata Agent — Configuration Guide

## Options

### `hostname` (required)
The name this node will appear as in Netdata dashboards.

**Default:** `haos`  
**Example:** `my-home-assistant`

---

### `streaming_enabled` (required)
Set to `true` to stream metrics to a parent Netdata instance.  
Set to `false` for standalone mode — metrics are only available on the local dashboard (`http://<ha-ip>:19999`).

**Default:** `false`

---

### `parent_url` (required when streaming)
Address of your Netdata parent node in `HOST:PORT` format.

**Example:** `192.168.1.10:19999`

Leave empty when `streaming_enabled` is `false`.

---

### `api_key` (required when streaming)
The API key (UUID) that authorizes this child to stream to the parent.

Generate one with:
```bash
python3 -c "import uuid; print(uuid.uuid4())"
```

Then add the matching entry to your parent node's `/etc/netdata/stream.conf`:
```ini
[your-generated-uuid]
    enabled = yes
    allow from = *
    default memory mode = dbengine
    health enabled by default = auto
```

Leave empty when `streaming_enabled` is `false`.

---

## Local Dashboard

When the add-on is running, the local Netdata dashboard is available at:

```
http://<your-ha-ip>:19999
```

This dashboard shows real-time metrics for the Home Assistant host including CPU, RAM, disk I/O, network traffic, and system load.

---

## Streaming Setup (Parent → Child)

To stream metrics to a self-hosted Netdata parent (e.g., a VPS or monitoring server):

1. **On the parent node**, add the following to `/etc/netdata/stream.conf`:

    ```ini
    [<your-api-key>]
        enabled = yes
        allow from = <ha-tailscale-or-local-ip>
        default memory mode = dbengine
        health enabled by default = auto
    ```

2. **In this add-on**, set:
    - `streaming_enabled: true`
    - `parent_url: <parent-ip>:19999`
    - `api_key: <your-api-key>`

3. Restart the add-on. Within a few seconds the HAOS node appears as a child in your parent Netdata dashboard.

---

## Network Requirements

| Direction | Source | Destination | Port |
|-----------|--------|-------------|------|
| Outbound (streaming) | HAOS | Netdata parent | 19999/TCP |
| Inbound (local dashboard) | Browser | HAOS | 19999/TCP |

If your parent node is on Tailscale, make sure the HAOS host is also connected to the same Tailscale network (via the Tailscale add-on for Home Assistant).
