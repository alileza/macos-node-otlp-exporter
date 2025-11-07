# macOS Node OTLP Exporter Action

A GitHub Action that installs and configures `node_exporter` and `otelcol-contrib` on macOS runners for OTLP metrics export.

## Features

- ✅ **No Homebrew dependency** - Downloads binaries directly from GitHub releases
- ✅ **Automatic service management** - Uses launchctl for persistent services
- ✅ **Configurable OTLP endpoint** - Send metrics to any OTLP-compatible backend
- ✅ **Custom resource attributes** - Add custom labels and metadata
- ✅ **Multiple commands** - Install, status check, stop, and logs

## Usage

### Basic Usage

```yaml
name: Setup Metrics Export
on: [push]

jobs:
  setup-metrics:
    runs-on: macos-latest
    steps:
      - name: Setup Node OTLP Exporter
        uses: your-org/macos-node-otlp-exporter@v1
        with:
          otlp_endpoint: 'https://otlp.your-domain.com:4318'
          otlp_auth: 'dXNlcjpwYXNzd29yZA=='  # base64("user:password")
```

### Advanced Usage

```yaml
name: Setup Metrics Export
on: [push]

jobs:
  setup-metrics:
    runs-on: macos-latest
    steps:
      - name: Setup Node OTLP Exporter
        uses: your-org/macos-node-otlp-exporter@v1
        with:
          otlp_endpoint: 'https://otlp.your-domain.com:4318'
          otlp_auth: ${{ secrets.OTLP_AUTH }}
          service_name: 'ci-runner'
          host_type: 'github-macos'
          custom_labels: 'environment=ci,team=platform,region=us-west'
          node_exporter_version: '1.10.2'
          otelcol_version: '0.139.0'
          command: 'install'
      
      - name: Check Status
        uses: your-org/macos-node-otlp-exporter@v1
        with:
          command: 'status'
      
      # Your build steps here
      - name: Build and Test
        run: |
          # Your build commands
          echo "Running tests with metrics collection..."
      
      - name: Stop Services
        if: always()
        uses: your-org/macos-node-otlp-exporter@v1
        with:
          command: 'stop'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `otlp_endpoint` | OTLP endpoint URL | No | `https://otlp.example.com:4318` |
| `otlp_auth` | Base64 encoded basic auth credentials | No | `dXNlcjpwYXNz` |
| `node_exporter_version` | node_exporter version to install | No | `1.10.2` |
| `otelcol_version` | otelcol-contrib version to install | No | `0.139.0` |
| `service_name` | Service name for OTEL resource attributes | No | `node-exporter` |
| `host_type` | Host type for OTEL resource attributes | No | `macos` |
| `custom_labels` | Additional custom labels (comma-separated key=value pairs) | No | `""` |
| `command` | Command to run: `install`, `status`, `stop`, `logs` | No | `install` |

## Commands

- **`install`** - Downloads binaries, configures services, and starts them
- **`status`** - Shows the status of both services
- **`stop`** - Stops both services
- **`logs`** - Tails the logs from both services (use with caution in CI)

## Authentication

The `otlp_auth` input should be a base64-encoded string of `username:password` for HTTP Basic Authentication.

```bash
# Generate auth string
echo -n "username:password" | base64
```

Store this in GitHub Secrets for security:

```yaml
otlp_auth: ${{ secrets.OTLP_AUTH }}
```

## Custom Labels

Add custom resource attributes using the `custom_labels` input:

```yaml
custom_labels: 'environment=production,team=platform,datacenter=us-west-2'
```

## What Gets Installed

- **node_exporter**: Downloads from [prometheus/node_exporter](https://github.com/prometheus/node_exporter/releases)
- **otelcol-contrib**: Downloads from [open-telemetry/opentelemetry-collector-releases](https://github.com/open-telemetry/opentelemetry-collector-releases/releases)
- **Services**: Creates launchctl plists for automatic startup
- **Configuration**: OTEL collector config with Prometheus scraping

## Endpoints

After installation:
- node_exporter metrics: `http://localhost:9100/metrics`
- OTLP export: Configured endpoint with HTTP Basic Auth

## Logs

Service logs are stored in:
- node_exporter: `~/Library/Logs/node_exporter.{log,err.log}`  
- otelcol-contrib: `~/Library/Logs/otelcol-contrib.{out,err}.log`

## Example OTLP Configuration

The action automatically configures the OTLP collector to:
1. Scrape node_exporter metrics from `localhost:9100`
2. Add resource detection (host info)
3. Add custom host.ip attribute
4. Add custom labels as resource attributes
5. Export to your OTLP endpoint with authentication

## Local Development

You can also run the script directly:

```bash
# Set environment variables
export OTLP_ENDPOINT="https://otlp.your-domain.com:4318"
export OTLP_BASIC_B64="$(echo -n 'user:pass' | base64)"
export CUSTOM_LABELS="env=dev,team=platform"

# Run commands
./nodemon.sh install
./nodemon.sh status  
./nodemon.sh stop
```

## Requirements

- macOS runner (GitHub Actions `macos-latest` or `macos-*`)
- No additional dependencies (no Homebrew required)

## License

MIT