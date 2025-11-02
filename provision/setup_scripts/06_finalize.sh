#!/bin/bash

set -e

echo "🎯 Finalizing configuration..."

# Create /etc/demo directory and deploy .venv
sudo mkdir -p /etc/demo
sudo cp config/.venv /etc/demo/

# Set proper permissions so Apache/PHP can read the .venv file
sudo chmod 644 /etc/demo/.venv
sudo chown root:www-data /etc/demo/.venv

echo "✅ Central .venv file deployed to /etc/demo/.venv"
echo "✅ Permissions set for Apache/PHP access"

# Test that www-data can read the file
if sudo -u www-data cat /etc/demo/.venv > /dev/null 2>&1; then
    echo "✅ Confirmed: Apache can read .venv file"
else
    echo "❌ Warning: Apache cannot read .venv file"
fi

echo "✅ All services will use /etc/demo/.venv for configuration"
echo ""
echo "🎉 Provisioning completed!"
