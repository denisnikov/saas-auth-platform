#!/bin/bash

set -e  # Exit on any error

echo "🚀 Starting Authentication System Provisioning"
echo "=============================================="

# Configuration
PROVISION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_SCRIPTS_DIR="$PROVISION_DIR/setup_scripts"
SYSTEM_SCRIPTS_DIR="$PROVISION_DIR/system_scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Use a regular user with sudo access."
fi

# Make all scripts executable
chmod +x $SETUP_SCRIPTS_DIR/*.sh
chmod +x $SYSTEM_SCRIPTS_DIR/*.py
chmod +x $PROVISION_DIR/start_services.sh

# Execute provisioning scripts in order
log "Step 1: Installing basic utilities..."
$SETUP_SCRIPTS_DIR/01_basic_utilities.sh

log "Step 2: Setting up web server and PHP..."
$SETUP_SCRIPTS_DIR/02_web_setup.sh

log "Step 3: Configuring MySQL database..."
$SETUP_SCRIPTS_DIR/03_mysql_setup.sh

log "Step 4: Setting up Python API..."
$SETUP_SCRIPTS_DIR/04_python_api.sh

log "Step 5: Configuring cron jobs..."
$SETUP_SCRIPTS_DIR/05_cron_jobs.sh

log "Step 6: Finalizing configuration..."
$SETUP_SCRIPTS_DIR/06_finalize.sh

log "Provisioning completed successfully! 🎉"
echo ""
echo "Next steps:"
echo "1. Run: ./start_services.sh"
echo "2. Access web interface: http://$(hostname -I | awk '{print $1}')/login.php"
echo "3. API will be available: http://localhost:5000"
echo ""
