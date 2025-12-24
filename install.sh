#!/usr/bin/env bash

# ERPNext 15 Installation Script for Proxmox LXC
# Copyright (c) 2024
# Author: Your Name
# License: MIT

set -e
shopt -s inherit_errexit nullglob

YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

msg_info() {
    echo -ne " ${HOLD} ${YW}$1${CL}"
}

msg_ok() {
    echo -e "\r\033[K ${CM} ${GN}$1${CL}"
}

msg_error() {
    echo -e "\r\033[K ${CROSS} ${RD}$1${CL}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    msg_error "This script must be run as root"
    exit 1
fi

# Check Ubuntu version
msg_info "Checking Ubuntu version"
if [[ ! -f /etc/os-release ]]; then
    msg_error "Cannot determine OS version"
    exit 1
fi

source /etc/os-release
if [[ "$ID" != "ubuntu" ]] || [[ "${VERSION_ID}" != "22.04" && "${VERSION_ID}" != "24.04" ]]; then
    msg_error "This script requires Ubuntu 22.04 or 24.04"
    exit 1
fi
msg_ok "Ubuntu ${VERSION_ID} detected"

# Prompt for configuration
echo -e "\n${BL}═══════════════════════════════════════════════════════${CL}"
echo -e "${GN}ERPNext 15 Installation Configuration${CL}"
echo -e "${BL}═══════════════════════════════════════════════════════${CL}\n"

read -p "Enter site name (e.g., erp.example.com): " SITE_NAME
while [[ -z "$SITE_NAME" ]]; do
    read -p "Site name cannot be empty. Enter site name: " SITE_NAME
done

read -p "Enter MySQL root password: " -s MYSQL_ROOT_PASSWORD
echo
while [[ -z "$MYSQL_ROOT_PASSWORD" ]]; do
    read -p "Password cannot be empty. Enter MySQL root password: " -s MYSQL_ROOT_PASSWORD
    echo
done

read -p "Enter ERPNext Administrator password: " -s ADMIN_PASSWORD
echo
while [[ -z "$ADMIN_PASSWORD" ]]; do
    read -p "Password cannot be empty. Enter Administrator password: " -s ADMIN_PASSWORD
    echo
done

read -p "Install production setup with Nginx and SSL? (y/n): " PRODUCTION
PRODUCTION=${PRODUCTION,,}

if [[ "$PRODUCTION" == "y" ]]; then
    read -p "Enter email for Let's Encrypt: " LETSENCRYPT_EMAIL
    while [[ -z "$LETSENCRYPT_EMAIL" ]]; do
        read -p "Email cannot be empty. Enter email: " LETSENCRYPT_EMAIL
    done
fi

echo -e "\n${BL}═══════════════════════════════════════════════════════${CL}\n"

# Update system
msg_info "Updating system packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef"
msg_ok "System updated"

# Install required packages
msg_info "Installing system dependencies"
export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq \
    git python3-dev python3-pip python3-venv \
    software-properties-common libmysqlclient-dev \
    mariadb-server mariadb-client \
    redis-server \
    curl \
    supervisor \
    nginx \
    fontconfig \
    libssl-dev \
    wkhtmltopdf \
    xvfb libfontconfig \
    cron >/dev/null 2>&1
msg_ok "System dependencies installed"

# Install Node.js 18
msg_info "Installing Node.js 18"
# Completely purge all old Node.js packages
apt-get remove -y nodejs libnode-dev libnode72 2>/dev/null || true
apt-get purge -y nodejs libnode-dev libnode72 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true
# Force remove conflicting files
rm -rf /usr/include/node 2>/dev/null || true
rm -rf /usr/lib/node_modules 2>/dev/null || true
# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
msg_ok "Node.js $(node --version) installed"

# Install Yarn
msg_info "Installing Yarn"
npm install -g yarn >/dev/null 2>&1
msg_ok "Yarn installed"

# Configure MariaDB
msg_info "Configuring MariaDB"
systemctl start mariadb
systemctl enable mariadb &>/dev/null

cat > /etc/mysql/mariadb.conf.d/50-erpnext.cnf <<EOF
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOF

# Secure MariaDB
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';" 2>/dev/null || true
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS test;" 2>/dev/null
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;" 2>/dev/null

systemctl restart mariadb
msg_ok "MariaDB configured"

# Configure Redis
msg_info "Configuring Redis"
systemctl enable redis-server &>/dev/null
systemctl start redis-server
msg_ok "Redis configured"

# Create frappe user
msg_info "Creating frappe user"
if ! id -u frappe &>/dev/null; then
    useradd -m -s /bin/bash frappe
    usermod -aG sudo frappe
    echo "frappe ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/frappe
fi
msg_ok "Frappe user created"

# Install bench
msg_info "Installing Frappe Bench"
pip3 install --upgrade pip >/dev/null 2>&1
pip3 install frappe-bench >/dev/null 2>&1
msg_ok "Frappe Bench installed"

# Initialize bench
msg_info "Initializing Frappe Bench (this may take several minutes)"
cd /home/frappe
sudo -u frappe bench init --frappe-branch version-15 frappe-bench >/dev/null 2>&1
cd /home/frappe/frappe-bench
msg_ok "Frappe Bench initialized"

# Create new site
msg_info "Creating ERPNext site: ${SITE_NAME}"
sudo -u frappe bench new-site ${SITE_NAME} \
    --mariadb-root-password "${MYSQL_ROOT_PASSWORD}" \
    --admin-password "${ADMIN_PASSWORD}" \
    --no-mariadb-socket >/dev/null 2>&1
msg_ok "Site ${SITE_NAME} created"

# Install ERPNext
msg_info "Installing ERPNext app (this may take 10-15 minutes)"
sudo -u frappe bench get-app --branch version-15 erpnext >/dev/null 2>&1
sudo -u frappe bench --site ${SITE_NAME} install-app erpnext >/dev/null 2>&1
msg_ok "ERPNext installed"

# Install additional apps (optional)
msg_info "Installing HRMS app"
sudo -u frappe bench get-app --branch version-15 hrms >/dev/null 2>&1
sudo -u frappe bench --site ${SITE_NAME} install-app hrms >/dev/null 2>&1
msg_ok "HRMS installed"

# Configure production
if [[ "$PRODUCTION" == "y" ]]; then
    msg_info "Setting up production environment"
    
    # Setup production
    sudo -u frappe bench setup production frappe --yes >/dev/null 2>&1
    
    # Setup SSL
    if [[ -n "$LETSENCRYPT_EMAIL" ]]; then
        msg_info "Setting up SSL with Let's Encrypt"
        sudo -u frappe bench setup lets-encrypt ${SITE_NAME} --email ${LETSENCRYPT_EMAIL} >/dev/null 2>&1 || true
        msg_ok "SSL configured"
    fi
    
    msg_ok "Production environment configured"
else
    msg_info "Configuring development environment"
    
    # Add site to hosts
    echo "127.0.0.1 ${SITE_NAME}" >> /etc/hosts
    
    # Setup socketio
    sudo -u frappe bench setup socketio >/dev/null 2>&1
    
    # Setup supervisor (for background jobs)
    sudo -u frappe bench setup supervisor >/dev/null 2>&1
    supervisorctl reread >/dev/null 2>&1
    supervisorctl update >/dev/null 2>&1
    
    msg_ok "Development environment configured"
fi

# Set proper permissions
msg_info "Setting permissions"
chown -R frappe:frappe /home/frappe/frappe-bench
msg_ok "Permissions set"

# Enable and start services
msg_info "Starting services"
if [[ "$PRODUCTION" == "y" ]]; then
    systemctl enable nginx >/dev/null 2>&1
    systemctl restart nginx >/dev/null 2>&1
    systemctl enable supervisor >/dev/null 2>&1
    systemctl restart supervisor >/dev/null 2>&1
else
    systemctl enable supervisor >/dev/null 2>&1
    systemctl restart supervisor >/dev/null 2>&1
fi
msg_ok "Services started"

# Cleanup
msg_info "Cleaning up"
apt-get autoremove -y >/dev/null 2>&1
apt-get autoclean -y >/dev/null 2>&1
msg_ok "Cleanup completed"

# Display completion message
IP=$(hostname -I | awk '{print $1}')
echo -e "\n${BL}═══════════════════════════════════════════════════════${CL}"
echo -e "${GN}ERPNext 15 Installation Complete!${CL}"
echo -e "${BL}═══════════════════════════════════════════════════════${CL}\n"
echo -e "${DGN}Site Name:${CL} ${SITE_NAME}"
echo -e "${DGN}Admin User:${CL} Administrator"
echo -e "${DGN}Admin Password:${CL} ${ADMIN_PASSWORD}"

if [[ "$PRODUCTION" == "y" ]]; then
    echo -e "${DGN}Access URL:${CL} https://${SITE_NAME}"
else
    echo -e "${DGN}Access URL:${CL} http://${IP}:8000"
    echo -e "\n${YW}To start the development server, run:${CL}"
    echo -e "  cd /home/frappe/frappe-bench"
    echo -e "  bench start"
fi

echo -e "\n${DGN}Bench Location:${CL} /home/frappe/frappe-bench"
echo -e "${DGN}User:${CL} frappe"
echo -e "\n${YW}Useful Commands:${CL}"
echo -e "  cd /home/frappe/frappe-bench"
echo -e "  bench restart"
echo -e "  bench update"
echo -e "  bench backup"
echo -e "  bench migrate"
echo -e "\n${BL}═══════════════════════════════════════════════════════${CL}\n"
