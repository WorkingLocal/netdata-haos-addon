#!/bin/bash
# Netdata Agent — Home Assistant OS Add-on startup script
# Reads HA options (/data/options.json) and configures Netdata before starting.

set -e

OPTIONS="/data/options.json"

# ── Parse HA options ──────────────────────────────────────────────────────────

parse_option() {
    python3 -c "import json,sys; d=json.load(open('$OPTIONS')); print(d.get('$1', '$2'))" 2>/dev/null || echo "$2"
}

if [ -f "$OPTIONS" ]; then
    HOSTNAME=$(parse_option "hostname" "haos")
    STREAMING=$(parse_option "streaming_enabled" "false")
    PARENT_URL=$(parse_option "parent_url" "")
    API_KEY=$(parse_option "api_key" "")
else
    echo "[netdata-agent] WARNING: /data/options.json not found, using defaults"
    HOSTNAME="haos"
    STREAMING="false"
    PARENT_URL=""
    API_KEY=""
fi

echo "[netdata-agent] Hostname:  ${HOSTNAME}"
echo "[netdata-agent] Streaming: ${STREAMING}"
[ -n "$PARENT_URL" ] && echo "[netdata-agent] Parent:    ${PARENT_URL}"

# ── Write netdata.conf ────────────────────────────────────────────────────────

cat > /etc/netdata/netdata.conf << EOF
[global]
    hostname = ${HOSTNAME}

[db]
    dbengine tier 0 retention time = 1d

[web]
    bind to = 0.0.0.0:19999
EOF

# ── Write stream.conf ─────────────────────────────────────────────────────────

if [ "$STREAMING" = "True" ] || [ "$STREAMING" = "true" ]; then
    if [ -z "$PARENT_URL" ] || [ -z "$API_KEY" ]; then
        echo "[netdata-agent] ERROR: streaming_enabled is true but parent_url or api_key is empty"
        echo "[netdata-agent] Streaming disabled — configure parent_url and api_key in add-on options"
        STREAMING="false"
    fi
fi

if [ "$STREAMING" = "True" ] || [ "$STREAMING" = "true" ]; then
    cat > /etc/netdata/stream.conf << EOF
[stream]
    enabled = yes
    destination = ${PARENT_URL}
    api key = ${API_KEY}
    timeout seconds = 60
    buffer size bytes = 1048576
    reconnect delay seconds = 5
EOF
    echo "[netdata-agent] Streaming enabled → ${PARENT_URL}"
else
    cat > /etc/netdata/stream.conf << EOF
[stream]
    enabled = no
EOF
    echo "[netdata-agent] Streaming disabled (standalone mode)"
fi

# ── Start Netdata ─────────────────────────────────────────────────────────────

echo "[netdata-agent] Starting Netdata..."
exec /usr/sbin/netdata -D
