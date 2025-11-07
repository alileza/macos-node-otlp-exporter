# Troubleshooting Guide

Common issues and solutions for the macOS Node OTLP Exporter action.

## Workflow Failures

### 1. Permission Denied Errors

**Error**: `Permission denied` or `403 Forbidden`

**Solution**: Ensure your repository has the correct permissions:
- Go to **Settings** → **Actions** → **General**
- Under "Workflow permissions", select "Read and write permissions"
- Check "Allow GitHub Actions to create and approve pull requests"

### 2. Deprecated Action Warnings

**Error**: `actions/create-release@v1` is deprecated

**Solution**: This has been fixed in the latest version. Update to the latest version:
```yaml
uses: alileza/macos-node-otlp-exporter@v1
```

### 3. Tag Already Exists Error

**Error**: `tag 'v1' already exists`

**Solution**: This is expected behavior. The workflow automatically handles tag updates.

## Action Usage Issues

### 1. Binary Download Fails

**Error**: `curl: (22) The requested URL returned error: 404 Not Found`

**Solution**: 
- Check the version numbers in your inputs
- Verify the versions exist on GitHub releases:
  - [node_exporter releases](https://github.com/prometheus/node_exporter/releases)
  - [otelcol-contrib releases](https://github.com/open-telemetry/opentelemetry-collector-releases/releases)

### 2. Service Fails to Start

**Error**: `otelcol-contrib` fails to start

**Common Causes**:
- Invalid OTLP endpoint URL
- Invalid base64 auth credentials
- Network connectivity issues

**Debug Steps**:
1. Check the action logs for specific error messages
2. Verify your OTLP endpoint is reachable
3. Test your auth credentials:
   ```bash
   echo "dXNlcjpwYXNz" | base64 -d  # Should output: user:pass
   ```

### 3. macOS Runner Issues

**Error**: Action fails on macOS runners

**Solutions**:
- Ensure you're using `runs-on: macos-latest` or `macos-*`
- This action only works on macOS runners
- Check if the runner has sufficient permissions for launchctl

## Configuration Issues

### 1. Custom Labels Not Applied

**Problem**: Custom labels don't appear in metrics

**Solution**: Check the format of your `custom_labels` input:
```yaml
# Correct format
custom_labels: 'environment=prod,team=platform,region=us-west'

# Incorrect format  
custom_labels: 'environment:prod,team:platform'  # Uses colons instead of =
```

### 2. OTLP Authentication Fails

**Problem**: 401 Unauthorized errors

**Solutions**:
1. Verify your auth credentials are base64 encoded:
   ```bash
   echo -n "username:password" | base64
   ```
2. Store credentials in GitHub Secrets:
   ```yaml
   otlp_auth: ${{ secrets.OTLP_AUTH }}
   ```

### 3. Service Status Shows "Not Registered"

**Problem**: `nodemon.sh status` shows services as not registered

**Cause**: This can happen if:
- Services were stopped manually
- launchctl registration failed
- Permissions issues

**Solution**:
```yaml
- name: Reinstall Services
  uses: alileza/macos-node-otlp-exporter@v1
  with:
    command: 'stop'

- name: Restart Services  
  uses: alileza/macos-node-otlp-exporter@v1
  with:
    command: 'install'
```

## Debugging Steps

### 1. Check Action Logs

1. Go to your repository's **Actions** tab
2. Click on the failed workflow run
3. Expand the failed step to see detailed logs

### 2. Enable Debug Logging

Add this to your workflow for more verbose output:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
```

### 3. Test Locally

You can test the script locally on macOS:
```bash
# Download the script
curl -O https://raw.githubusercontent.com/alileza/macos-node-otlp-exporter/main/nodemon.sh
chmod +x nodemon.sh

# Set environment variables
export OTLP_ENDPOINT="https://your-endpoint.com:4318"
export OTLP_BASIC_B64="$(echo -n 'user:pass' | base64)"

# Test commands
./nodemon.sh install
./nodemon.sh status
./nodemon.sh stop
```

### 4. Common Log Locations

If services start but don't work correctly, check these logs:
- `~/Library/Logs/node_exporter.log`
- `~/Library/Logs/node_exporter.err.log`
- `~/Library/Logs/otelcol-contrib.out.log`
- `~/Library/Logs/otelcol-contrib.err.log`

## Getting Help

If you're still having issues:

1. **Check existing issues**: https://github.com/alileza/macos-node-otlp-exporter/issues
2. **Create a new issue** with:
   - Your workflow YAML
   - Full error logs
   - Environment details (macOS version, etc.)
   - Steps to reproduce

## Version Compatibility

| Action Version | node_exporter | otelcol-contrib | Status |
|---------------|---------------|-----------------|---------|
| v1.0.x        | 1.10.2        | 0.139.0        | ✅ Supported |

For the latest version compatibility, check the [releases page](https://github.com/alileza/macos-node-otlp-exporter/releases).