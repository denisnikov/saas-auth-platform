#!/bin/bash

set -e

echo "🐍 Setting up Python API with virtual environment..."

# Create API directory
sudo mkdir -p /var/www/api
sudo chown $USER:$USER /var/www/api

# Copy API files with sudo
sudo cp api/app.py /var/www/api/
sudo cp config/.venv /var/www/api/

# Create and activate virtual environment
cd /var/www/api
python3 -m venv venv

# Install Python packages in the virtual environment
sudo ./venv/bin/pip install --upgrade pip
sudo ./venv/bin/pip install flask mysql-connector-python requests

# Set proper permissions
sudo chown -R www-data:www-data /var/www/api
sudo chmod 755 /var/www/api
sudo chmod 644 /var/www/api/app.py
sudo chmod 600 /var/www/api/.venv

echo "✅ Python API setup completed with virtual environment"
