#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# CONFIG — EDIT AS NEEDED OR SET VIA ENVIRONMENT VARIABLES
# ─────────────────────────────────────────────────────────────
OTLP_ENDPOINT="${OTLP_ENDPOINT:-https://otlp.example.com:4318}"
OTLP_BASIC_B64="${OTLP_BASIC_B64:-dXNlcjpwYXNz}"   # base64("user:pass")

NODE_EXPORTER_VERSION="${NODE_EXPORTER_VERSION:-1.10.2}"
OTELCOL_CONTRIB_VERSION="${OTELCOL_CONTRIB_VERSION:-0.139.0}"

# Custom labels for OTEL resource attributes
SERVICE_NAME="${SERVICE_NAME:-node-exporter}"
HOST_TYPE="${HOST_TYPE:-macos}"
CUSTOM_LABELS="${CUSTOM_LABELS:-}"
# ─────────────────────────────────────────────────────────────

BIN_DIR="$HOME/.local/bin"
CFG_DIR="$HOME/.config/otelcol-contrib"
LA_DIR="$HOME/Library/LaunchAgents"
OTEL_PLIST="$LA_DIR/otelcol-contrib.plist"
OTEL_BIN="$BIN_DIR/otelcol-contrib"
OTEL_CFG="$CFG_DIR/config.yaml"

NODE_BIN="$BIN_DIR/node_exporter"
NODE_PLIST="$LA_DIR/node-exporter.plist"
OTEL_LABEL="otelcol-contrib"
NODE_LABEL="node-exporter"

NODE_LOG="$HOME/Library/Logs/node_exporter.log"
NODE_ERR="$HOME/Library/Logs/node_exporter.err.log"
OTEL_OUT="$HOME/Library/Logs/otelcol-contrib.out.log"
OTEL_ERR="$HOME/Library/Logs/otelcol-contrib.err.log"

install_node_exporter() {
  echo "==> Installing node_exporter ${NODE_EXPORTER_VERSION}"
  
  case "$(uname -m)" in
    arm64)  ARCH="darwin-arm64" ;;
    x86_64) ARCH="darwin-amd64" ;;
    *) echo "Unsupported arch"; exit 1 ;;
  esac

  NE_FILE="node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
  NE_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${NE_FILE}"

  curl -fsSL "$NE_URL" -o "/tmp/${NE_FILE}"
  tar -xzf "/tmp/${NE_FILE}" -C /tmp
  install -m 0755 "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}/node_exporter" "$NODE_BIN"
  rm -rf "/tmp/${NE_FILE}" "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}"
}

detect_ip() {
  iface=$(route get default 2>/dev/null | awk '/interface:/{print $2}' || true)
  if [[ -n "${iface:-}" ]]; then
    ip=$(ipconfig getifaddr "$iface" 2>/dev/null || true)
    [[ -n "$ip" ]] && echo "$ip" && return
  fi
  for i in en0 en1 en2; do
    ip=$(ipconfig getifaddr "$i" 2>/dev/null || true)
    [[ -n "$ip" ]] && echo "$ip" && return
  done
  echo "127.0.0.1"
}

cmd_install() {
  mkdir -p "$BIN_DIR" "$CFG_DIR" "$LA_DIR"
  
  install_node_exporter

  echo "==> Installing otelcol-contrib"

  case "$(uname -m)" in
    arm64)  ARCH="darwin_arm64" ;;
    x86_64) ARCH="darwin_amd64" ;;
    *) echo "Unsupported arch"; exit 1 ;;
  esac

  OC_FILE="otelcol-contrib_${OTELCOL_CONTRIB_VERSION}_${ARCH}.tar.gz"
  OC_URL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTELCOL_CONTRIB_VERSION}/${OC_FILE}"

  curl -fsSL "$OC_URL" -o "/tmp/${OC_FILE}"
  tar -xzf "/tmp/${OC_FILE}" -C /tmp
  install -m 0755 "/tmp/otelcol-contrib" "$OTEL_BIN"
  rm -f "/tmp/${OC_FILE}" "/tmp/otelcol-contrib"

  if ! grep -q 'export PATH="$HOME/.local/bin' ~/.zshrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    echo "==> Added $HOME/.local/bin to PATH in ~/.zshrc"
  fi

  IP=$(detect_ip)
  launchctl setenv HOST_IP "$IP"
  echo "==> host.ip = $IP"
  
  # Build resource attributes
  RESOURCE_ATTRS="service.name=${SERVICE_NAME},host.type=${HOST_TYPE}"
  if [[ -n "$CUSTOM_LABELS" ]]; then
    RESOURCE_ATTRS="${RESOURCE_ATTRS},${CUSTOM_LABELS}"
  fi
  echo "==> resource attributes: $RESOURCE_ATTRS"

  cat > "$OTEL_CFG" <<EOF
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: node
          static_configs:
            - targets: ['localhost:9100']

processors:
  resourcedetection:
    detectors: [env, system]
  attributes/add_host_ip:
    actions:
      - key: host.ip
        value: "${IP}"
        action: upsert
  batch:

exporters:
  otlphttp:
    endpoint: ${OTLP_ENDPOINT}
    headers:
      Authorization: "Basic ${OTLP_BASIC_B64}"

service:
  pipelines:
    metrics:
      receivers: [prometheus]
      processors: [resourcedetection, attributes/add_host_ip, batch]
      exporters: [otlphttp]
EOF

  cat > "$NODE_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>${NODE_LABEL}</string>
	<key>ProgramArguments</key>
	<array>
		<string>${NODE_BIN}</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
	<key>StandardOutPath</key>
	<string>${NODE_LOG}</string>
	<key>StandardErrorPath</key>
	<string>${NODE_ERR}</string>
</dict>
</plist>
EOF

  cat > "$OTEL_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>${OTEL_LABEL}</string>
	<key>ProgramArguments</key>
	<array>
		<string>${OTEL_BIN}</string>
		<string>--config</string>
		<string>${OTEL_CFG}</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
	<key>StandardOutPath</key>
	<string>${OTEL_OUT}</string>
	<key>StandardErrorPath</key>
	<string>${OTEL_ERR}</string>
</dict>
</plist>
EOF

  echo "==> Enabling services"
  launchctl unload "$NODE_PLIST" >/dev/null 2>&1 || true
  launchctl load -w "$NODE_PLIST"
  launchctl unload "$OTEL_PLIST" >/dev/null 2>&1 || true
  launchctl load -w "$OTEL_PLIST"

  echo "✅ Installed."
}

cmd_status() {
  echo "==> node_exporter"
  if launchctl list | grep -q "$NODE_LABEL" 2>/dev/null; then
    echo "  ✅ launchctl registered"
  else
    echo "  ❌ not registered"
  fi
  pgrep -f node_exporter >/dev/null && echo "  ✅ running" || echo "  ❌ not running"

  echo
  echo "==> otelcol-contrib"
  if launchctl list | grep -q "$OTEL_LABEL" 2>/dev/null; then
    echo "  ✅ launchctl registered"
  else
    echo "  ❌ not registered"
  fi
  pgrep -f otelcol-contrib >/dev/null && echo "  ✅ running" || echo "  ❌ not running"
}

cmd_stop() {
  echo "==> stopping node_exporter"
  launchctl unload -w "$NODE_PLIST" >/dev/null 2>&1 || true

  echo "==> stopping otelcol-contrib"
  launchctl unload -w "$OTEL_PLIST" >/dev/null 2>&1 || true

  echo "✅ Stopped."
}

cmd_logs() {
  touch "$NODE_LOG" "$NODE_ERR" "$OTEL_OUT" "$OTEL_ERR"

  echo "==> tailing logs (CTRL-C to exit)"
  tail -F "$NODE_LOG" "$NODE_ERR" "$OTEL_OUT" "$OTEL_ERR"
}

usage() {
  echo
  echo "Usage:"
  echo "  nodemon install   # install + start"
  echo "  nodemon status    # show status"
  echo "  nodemon stop      # stop services"
  echo "  nodemon logs      # tail logs"
  echo
  exit 1
}

cmd="${1:-}"
case "$cmd" in
  install) cmd_install ;;
  status)  cmd_status ;;
  stop)    cmd_stop ;;
  logs)    cmd_logs ;;
  *)       usage ;;
esac
