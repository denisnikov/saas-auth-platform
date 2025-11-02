#!/bin/bash

set -e

echo "🎯 Finalizing configuration..."

# Create /etc/demo directory and deploy .venv
sudo mkdir -p /etc/demo
sudo cp config/.venv /etc/demo/
sudo chmod 600 /etc/demo/.venv
sudo chown root:root /etc/demo/.venv

echo "✅ Central .venv file deployed to /etc/demo/.venv"
echo "✅ All services will use /etc/demo/.venv for configuration"
echo ""
echo "🎉 Provisioning completed!"
