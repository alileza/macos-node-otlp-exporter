#!/usr/bin/env bash
# Test script to validate workflow logic

set -euo pipefail

echo "==> Testing Workflow Configuration"

# Test workflow files exist
WORKFLOWS=(
  ".github/workflows/update-v1-tag.yml"
  ".github/workflows/release.yml" 
  ".github/workflows/example.yml"
)

for workflow in "${WORKFLOWS[@]}"; do
  if [[ ! -f "$workflow" ]]; then
    echo "❌ Missing workflow: $workflow"
    exit 1
  fi
  echo "✅ Found: $workflow"
done

# Test that workflows have correct triggers
echo ""
echo "==> Checking Workflow Triggers"

if ! grep -q "branches:" .github/workflows/update-v1-tag.yml; then
  echo "❌ update-v1-tag.yml missing branch trigger"
  exit 1
fi

if ! grep -q "main" .github/workflows/update-v1-tag.yml; then
  echo "❌ update-v1-tag.yml not triggered on main branch"
  exit 1
fi

if ! grep -q "paths:" .github/workflows/update-v1-tag.yml; then
  echo "❌ update-v1-tag.yml missing path filters"
  exit 1
fi

echo "✅ update-v1-tag.yml has correct triggers"

# Test that paths include the right files
REQUIRED_PATHS=("action.yml" "nodemon.sh" "README.md")
for path in "${REQUIRED_PATHS[@]}"; do
  if ! grep -q "$path" .github/workflows/update-v1-tag.yml; then
    echo "❌ update-v1-tag.yml missing path: $path"
    exit 1
  fi
done

echo "✅ update-v1-tag.yml monitors correct files"

# Test example workflow uses correct action syntax
if grep -q "uses: \\./" .github/workflows/example.yml; then
  echo "✅ example.yml uses local action reference (correct for testing)"
else
  echo "❌ example.yml missing local action references"
  exit 1
fi

# Test that action.yml has required fields
REQUIRED_FIELDS=("name" "description" "runs" "inputs")
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! grep -q "$field:" action.yml; then
    echo "❌ action.yml missing field: $field"
    exit 1
  fi
done

echo "✅ action.yml has required fields"

# Test that action.yml uses composite action
if ! grep -q "using: 'composite'" action.yml; then
  echo "❌ action.yml not using composite action type"
  exit 1
fi

echo "✅ action.yml uses composite action type"

echo ""
echo "✅ All workflow tests passed!"
echo ""
echo "📋 Summary:"
echo "  - 3 workflow files validated"
echo "  - Correct triggers configured"
echo "  - Path filters include all action files" 
echo "  - Action.yml properly structured"
echo ""
echo "🚀 Ready for GitHub Actions!"