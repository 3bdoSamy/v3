#!/bin/bash

# o11-v3 Professional Installer
# Script by: 3BdALLaH

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
step() { echo -e "${BLUE}[STEP]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then error "Please run as root or use sudo"; fi

echo -e "${CYAN}"
echo "================================================"
echo "       o11-v3 Professional Installer"
echo "           Script by: 3BdALLaH"
echo "================================================"
echo -e "${NC}"

# Configuration
SERVICE_PORT="2086"
INSTALL_DIR="/home/o11"
SERVICE_NAME="o11.service"
DOWNLOAD_URL="https://senator.pages.dev/v3p.zip"

step "Using default port: $SERVICE_PORT"

step "Updating system and installing dependencies..."
apt update && apt upgrade -y
apt install -y ffmpeg unzip wget

step "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || error "Failed to change to directory: $INSTALL_DIR"

step "Downloading v3p package..."
wget -q "$DOWNLOAD_URL" -O v3p.zip
if [ ! -f v3p.zip ]; then error "Failed to download v3p.zip"; fi

step "Extracting package..."
unzip -q v3p.zip
rm -f v3p.zip

step "Setting executable permissions..."
if [ ! -f "v3p_launcher" ]; then error "v3p_launcher not found after extraction"; fi
chmod +x v3p_launcher
chmod -R 755 "$INSTALL_DIR"

step "Creating systemd service..."
cat > /etc/systemd/system/$SERVICE_NAME << EOF
[Unit]
Description=o11 Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/v3p_launcher -p $SERVICE_PORT -noramfs
ExecStop=/bin/kill -TERM \$MAINPID
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=infinity
LimitNPROC=infinity
StandardOutput=journal
StandardError=journal

# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes

[Install]
WantedBy=multi-user.target
EOF

step "Reloading systemd and enabling service..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

step "Starting o11 service..."
if systemctl restart "$SERVICE_NAME"; then
    success "Service started successfully!"
else
    warning "Service failed to start. Checking status..."
    systemctl status "$SERVICE_NAME" --no-pager -l
    error "Service failed to start. Please check logs with: journalctl -u $SERVICE_NAME"
fi

step "Waiting for service to initialize..."
sleep 5

if systemctl is-active --quiet "$SERVICE_NAME"; then
    success "Service is running successfully!"
else
    warning "Service is not running. Checking status..."
    systemctl status "$SERVICE_NAME" --no-pager -l
    error "Service failed to start. Please check the logs above."
fi

# Get IP address for display
IP_ADDRESS=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

# Display installation summary
echo -e "${GREEN}"
echo "================================================"
echo "          o11-v3 INSTALLATION COMPLETE         "
echo "================================================"
echo -e "${NC}"
echo "IP Address: $IP_ADDRESS"
echo "Service Port: $SERVICE_PORT"
echo "Installation Directory: $INSTALL_DIR"
echo "Service Name: $SERVICE_NAME"
echo ""
echo "Access URL: http://$IP_ADDRESS:$SERVICE_PORT"
echo ""
echo "Useful Commands:"
echo "Check status:    systemctl status $SERVICE_NAME"
echo "View logs:       journalctl -u $SERVICE_NAME -f"
echo "Restart service: systemctl restart $SERVICE_NAME"
echo "Stop service:    systemctl stop $SERVICE_NAME"
echo ""
echo -e "${CYAN}================================================"
echo "This installation was configured by 3BdALLaH"
echo -e "================================================${NC}"
echo ""
echo -e "${GREEN}Installation completed successfully!${NC}"

success "Cleanup completed. Installation finished!"
