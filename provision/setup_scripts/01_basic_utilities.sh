#!/bin/bash

set -e

echo "🔧 Installing basic utilities..."

# Update package list
sudo apt update

# Install essential utilities
sudo apt install -y \
    git \
    vim \
    zsh \
    curl \
    wget \
    screen \
    python3 \
    python3-pip \
    python3-venv \
    php \
    php-mysql \
    libapache2-mod-php \
    mariadb-server

# Verify installations
echo "✅ Basic utilities installed:"
python3 --version
pip3 --version
php --version
screen --version

echo "🎯 Basic utilities setup completed"
