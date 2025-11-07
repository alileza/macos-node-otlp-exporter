#!/usr/bin/env bash
# Simple test script to validate GitHub Action structure

set -euo pipefail

echo "==> Testing GitHub Action Structure"

# Check required files exist
if [[ ! -f "action.yml" ]]; then
  echo "❌ Missing action.yml"
  exit 1
fi

if [[ ! -f "nodemon.sh" ]]; then
  echo "❌ Missing nodemon.sh"  
  exit 1
fi

if [[ ! -x "nodemon.sh" ]]; then
  echo "❌ nodemon.sh is not executable"
  exit 1
fi

# Validate action.yml syntax
if ! python3 -c "import yaml; yaml.safe_load(open('action.yml'))" 2>/dev/null; then
  echo "❌ Invalid action.yml syntax"
  exit 1
fi

echo "✅ action.yml exists and is valid YAML"
echo "✅ nodemon.sh exists and is executable"

# Test environment variable handling
export OTLP_ENDPOINT="https://test.example.com:4318"
export OTLP_BASIC_B64="dGVzdA=="
export SERVICE_NAME="test-service"
export CUSTOM_LABELS="test=true"

# Test that script picks up environment variables
if ! grep -q 'OTLP_ENDPOINT="${OTLP_ENDPOINT:-' nodemon.sh; then
  echo "❌ Script doesn't support OTLP_ENDPOINT environment variable"
  exit 1
fi

echo "✅ Environment variable support detected"

# Test basic commands without actually running them
for cmd in install status stop logs; do
  if ! grep -q "cmd_${cmd}(" nodemon.sh; then
    echo "❌ Missing command: $cmd"
    exit 1  
  fi
done

echo "✅ All required commands found"

echo "✅ GitHub Action structure validation passed!"
echo ""
echo "📦 Ready to publish as GitHub Action"
echo "📝 See README.md for usage instructions"