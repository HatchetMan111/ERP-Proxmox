#!/bin/bash
# =================================================================
# ERPNext Installation Script - FIXED VENV VERSION
# =================================================================

set -e # Bricht bei Fehlern sofort ab

# Farben
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Starte Reparatur und Installation...${NC}"

# 1. System-Abhängigkeiten (erweitert)
apt-get update
apt-get install -y python3-dev python3-pip python3-venv \
    mariadb-server mariadb-client redis-server git \
    curl sudo nodejs npm

# 2. Frappe User & Berechtigungen
if ! id "frappe" &>/dev/null; then
    useradd -m -s /bin/bash frappe
    usermod -aG sudo frappe
    echo "frappe ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

# 3. Bench Installation via VENV (Löst das "command not found" Problem)
echo -e "${BLUE}Installiere Frappe-Bench...${NC}"
python3 -m venv /opt/bench-venv
/opt/bench-venv/bin/pip install frappe-bench
ln -sf /opt/bench-venv/bin/bench /usr/local/bin/bench

# 4. MariaDB Config (Sicherstellen, dass es läuft)
cat <<EOF > /etc/mysql/mariadb.conf.d/erpnext.cnf
[mysqld]
innodb_file_per_table = 1
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
[mysql]
default-character-set = utf8mb4
EOF
systemctl restart mariadb

# 5. ERPNext Setup als User 'frappe'
# Wir nutzen hier absolute Pfade für bench
sudo -u frappe -H bash -c "
    cd /home/frappe
    # Falls Ordner existiert, löschen für sauberen Neustart
    rm -rf frappe-bench 
    
    bench init frappe-bench --frappe-branch version-15 --skip-redis-config-check
    cd frappe-bench
    bench get-app erpnext --branch version-15
    
    # Site erstellen (Nutzt Standard-Passwörter für den Test, ändere diese später!)
    bench new-site erp.local --mariadb-root-password 'admin' --admin-password 'admin' --install-app erpnext
"

# 6. Produktionseinrichtung
echo -e "${BLUE}Richte Produktion ein...${NC}"
cd /home/frappe/frappe-bench
bench setup production frappe --yes

echo -e "${GREEN}Installation fertig! Login mit Administrator / admin${NC}"
