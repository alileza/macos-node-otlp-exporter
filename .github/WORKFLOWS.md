# Workflow Documentation

This repository includes several GitHub Actions workflows for automated releases and testing.

## Workflows

### 1. `update-v1-tag.yml` - Automatic v1 Tag Update

**Trigger**: Push to `main` branch when action files change
**Purpose**: Automatically updates the `v1` tag to point to the latest commit

This allows users to always reference the latest stable version with:
```yaml
uses: your-org/macos-node-otlp-exporter@v1
```

**What it does**:
- Deletes existing `v1` tag (local and remote)
- Creates new `v1` tag pointing to the current commit
- Updates the remote tag

### 2. `release.yml` - Automated Releases

**Trigger**: Push to `main` branch or manual dispatch
**Purpose**: Creates semantic versioned releases based on commit messages

**Version Bump Logic**:
- **Major**: Commits containing `BREAKING`, `breaking change`, or `major:`
- **Minor**: Commits containing `feat:`, `feature:`, or `minor:`  
- **Patch**: All other commits (default)

**What it does**:
- Analyzes commit messages since last release
- Determines appropriate version bump
- Creates GitHub release with generated changelog
- Updates major version tag (e.g., `v1`) to point to new release

### 3. `example.yml` - Example Usage

**Trigger**: Manual dispatch or push to `main`
**Purpose**: Demonstrates how to use the action

**Test Steps**:
- Install the action
- Check service status
- Verify node_exporter endpoint
- Run simulated workload
- Check logs
- Clean up services

## Usage in External Repositories

When using this action in other repositories, replace `./` with the full action reference:

```yaml
# Instead of:
uses: ./

# Use:
uses: your-org/macos-node-otlp-exporter@v1
```

## Release Process

1. **Make changes** to action files (`action.yml`, `nodemon.sh`, `README.md`)
2. **Commit with semantic message**:
   ```bash
   git commit -m "feat: add custom labels support"    # Minor version
   git commit -m "fix: resolve configuration issue"   # Patch version  
   git commit -m "BREAKING: change input names"       # Major version
   ```
3. **Push to main**:
   ```bash
   git push origin main
   ```
4. **Workflows automatically**:
   - Update `v1` tag immediately
   - Create versioned release
   - Update major version tag

## Manual Release

You can also trigger releases manually:

1. Go to **Actions** tab
2. Select **Release and Tag** workflow
3. Click **Run workflow**
4. Choose branch and run

## Version Tags

After each release, multiple tags are available:

- **Specific version**: `v1.2.3` - Points to exact release
- **Major version**: `v1` - Always points to latest v1.x.x release
- **Latest**: Use `v1` for the most recent stable version

## Monitoring

Check the **Actions** tab to monitor:
- Successful tag updates
- Release creation status  
- Example workflow test results
- Any workflow failures

## Troubleshooting

**Tag update fails**:
- Check repository permissions
- Ensure `GITHUB_TOKEN` has appropriate access
- Verify branch protection rules allow tag updates

**Release creation fails**:
- Check commit message format
- Verify no duplicate tags exist
- Review workflow logs for specific errors