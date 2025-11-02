#!/bin/bash

set -e

echo "🐍 Setting up Python API with virtual environment..."

# Create API directory
sudo mkdir -p /var/www/api

# Copy API file
sudo cp api/app.py /var/www/api/

# Create virtual environment with sudo
cd /var/www/api
sudo python3 -m venv venv

# Install Python packages with sudo
sudo ./venv/bin/pip install --upgrade pip
sudo ./venv/bin/pip install flask mysql-connector-python requests

# Set ownership to www-data AFTER everything is installed
sudo chown -R www-data:www-data /var/www/api
sudo chmod 755 /var/www/api
sudo chmod 644 /var/www/api/app.py

echo "✅ Python API setup completed with virtual environment"
