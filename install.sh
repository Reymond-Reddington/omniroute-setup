#!/bin/bash
set -e

echo "=== OmniRoute Installation Script ==="
echo "This script will install OmniRoute on your VPS without affecting existing services."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (sudo ./install.sh)"
  exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is already installed
if ! command -v docker &> /dev/null; then
  log_info "Docker not found. Installing Docker..."
  apt update
  apt install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  log_info "Docker installed successfully"
else
  log_info "Docker is already installed"
fi

# Check if Nginx is already installed
if ! command -v nginx &> /dev/null; then
  log_info "Nginx not found. Installing Nginx..."
  apt install -y nginx
  log_info "Nginx installed successfully"
else
  log_info "Nginx is already installed"
fi

# Create OmniRoute directory
OMNIRoute_DIR="/opt/omniroute"
log_info "Creating OmniRoute directory at $OMNIRoute_DIR"
mkdir -p $OMNIRoute_DIR

# Check if OmniRoute is already running
if docker ps | grep -q omniroute; then
  log_warn "OmniRoute is already running. Stopping existing container..."
  docker stop omniroute || true
  docker rm omniroute || true
fi

# Generate secure random secrets
log_info "Generating secure secrets..."
JWT_SECRET=$(openssl rand -hex 32)
API_KEY_SECRET=$(openssl rand -hex 32)
STORAGE_ENCRYPTION_KEY=$(openssl rand -hex 32)
MACHINE_ID_SALT=$(openssl rand -hex 32)

# Create .env file
log_info "Creating .env configuration file..."
cat > $OMNIRoute_DIR/.env << EOF
# === Security ===
JWT_SECRET=$JWT_SECRET
INITIAL_PASSWORD=ChangeThisPassword123!
API_KEY_SECRET=$API_KEY_SECRET
STORAGE_ENCRYPTION_KEY=$STORAGE_ENCRYPTION_KEY
STORAGE_ENCRYPTION_KEY_VERSION=v1
MACHINE_ID_SALT=$MACHINE_ID_SALT

# === App ===
PORT=20128
NODE_ENV=production
HOSTNAME=0.0.0.0
DATA_DIR=/app/data
STORAGE_DRIVER=sqlite
APP_LOG_TO_FILE=true
AUTH_COOKIE_SECURE=false
REQUIRE_API_KEY=false

# === Domain ===
BASE_URL=http://$(curl -s ifconfig.me):20128
NEXT_PUBLIC_BASE_URL=http://$(curl -s ifconfig.me):20128
EOF

log_info ".env file created at $OMNIRoute_DIR/.env"
log_warn "IMPORTANT: Change INITIAL_PASSWORD in .env file after installation!"

# Pull and run OmniRoute
log_info "Pulling OmniRoute Docker image..."
docker pull diegosouzapw/omniroute:latest

log_info "Starting OmniRoute container..."
docker run -d \
  --name omniroute \
  --restart unless-stopped \
  --env-file $OMNIRoute_DIR/.env \
  -p 20128:20128 \
  -v omniroute-data:/app/data \
  diegosouzapw/omniroute:latest

sleep 3

if docker ps | grep -q omniroute; then
  log_info "OmniRoute container started successfully!"
  SERVER_IP=$(curl -s ifconfig.me)
  echo ""
  log_info "=== Installation Complete ==="
  echo ""
  echo "OmniRoute is now running at:"
  echo "  - Dashboard: http://$SERVER_IP:20128/dashboard"
  echo "  - API Endpoint: http://$SERVER_IP:20128/v1/chat/completions"
  echo ""
  echo "Default credentials:"
  echo "  - Password: ChangeThisPassword123!"
  echo ""
  log_warn "SECURITY: Change the password immediately after first login!"
  echo ""
  echo "To view logs: docker logs -f omniroute"
  echo "To stop: docker stop omniroute"
  echo "To restart: docker restart omniroute"
else
  log_error "Failed to start OmniRoute container. Check logs with: docker logs omniroute"
  exit 1
fi

echo "=== Script completed successfully ==="
