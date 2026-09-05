#!/bin/bash
set -e

echo "=== OmniRoute Installation Script ==="
echo "VPS IP: 89.251.8.32"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (sudo ./install.sh)"
  exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Install Docker if not present
if ! command -v docker &> /dev/null; then
  log_info "Installing Docker..."
  apt update
  apt install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  log_info "Docker installed"
else
  log_info "Docker already installed"
fi

# Stop existing container
if docker ps | grep -q omniroute; then
  log_warn "Stopping existing OmniRoute..."
  docker stop omniroute || true
  docker rm omniroute || true
fi

# Create directory
OMNIRoute_DIR="/opt/omniroute"
mkdir -p $OMNIRoute_DIR

# Generate secure secrets
log_info "Generating secure secrets..."
JWT_SECRET=$(openssl rand -hex 32)
API_KEY_SECRET=$(openssl rand -hex 32)
STORAGE_ENCRYPTION_KEY=$(openssl rand -hex 32)
MACHINE_ID_SALT=$(openssl rand -hex 32)

# Create .env file
cat > $OMNIRoute_DIR/.env << EOF
# === Security ===
JWT_SECRET=$JWT_SECRET
INITIAL_PASSWORD=OmniPass123!
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
BASE_URL=http://89.251.8.32:20128
NEXT_PUBLIC_BASE_URL=http://89.251.8.32:20128
EOF

log_info ".env file created"

# Pull and run
docker pull diegosouzapw/omniroute:latest

docker run -d \
  --name omniroute \
  --restart unless-stopped \
  --env-file $OMNIRoute_DIR/.env \
  -p 20128:20128 \
  -v omniroute-data:/app/data \
  diegosouzapw/omniroute:latest

sleep 5

if docker ps | grep -q omniroute; then
  log_info "=== Installation Complete ==="
  echo ""
  echo "OmniRoute is running at:"
  echo "  Dashboard: http://89.251.8.32:20128/dashboard"
  echo "  API: http://89.251.8.32:20128/v1/chat/completions"
  echo ""
  echo "Default Password: OmniPass123!"
  log_warn "Change password after first login!"
  echo ""
  echo "Logs: docker logs -f omniroute"
else
  log_error "Failed to start. Check: docker logs omniroute"
  exit 1
fi
