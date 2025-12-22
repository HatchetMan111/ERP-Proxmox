#!/bin/bash

# =================================================================
# ERPNext Installation Script (Proxmox VM / Ubuntu 24.04)
# Autor: HatchetMan111
# =================================================================

# Farben für die Konsole
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Header
echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}      Starte ERPNext Installation (Version 15)      ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Root-Check
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Fehler: Bitte als root ausführen!${NC}"
   exit 1
fi

# 2. Variablen-Abfrage (Benutzerfreundlich)
echo -e "${BLUE}Konfiguration der Installation:${NC}"
read -p "ERPNext Site Name (z.B. erp.local): " SITE_NAME
SITE_NAME=${SITE_NAME:-erp.local}

read -s -p "MariaDB Root Passwort: " DB_ROOT_PASS
echo ""
read -s -p "ERPNext Administrator Passwort: " ADMIN_PASS
echo ""

# 3. System-Update
echo -e "${BLUE}[1/7] Aktualisiere Systempakete...${NC}"
apt-get update && apt-get upgrade -y

# 4. Abhängigkeiten installieren
echo -e "${BLUE}[2/7] Installiere Software-Abhängigkeiten...${NC}"
apt-get install -y git python3-dev python3-pip python3-venv \
    mariadb-server mariadb-client redis-server wget curl cron sudo \
    libssl-dev pkg-config libmysqlclient-dev nodejs npm

# Node.js & Yarn Fix
npm install -g yarn

# 5. MariaDB Konfiguration (Wichtig für ERPNext!)
echo -e "${BLUE}[3/7] Konfiguriere Datenbank...${NC}"
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
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASS';"
mysql -u root -p"$DB_ROOT_PASS" -e "FLUSH PRIVILEGES;"

# 6. Frappe Benutzer anlegen
echo -e "${BLUE}[4/7] Erstelle Benutzer 'frappe'...${NC}"
if ! id "frappe" &>/dev/null; then
    useradd -m -s /bin/bash frappe
    usermod -aG sudo frappe
    echo "frappe ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

# 7. ERPNext Installation (als User frappe)
echo -e "${BLUE}[5/7] Installiere Frappe Bench & ERPNext (Dauert ca. 10 Min)...${NC}"
pip3 install frappe-bench --break-system-packages

sudo -u frappe -H bash -c "
    cd /home/frappe
    export PATH=\$PATH:/home/frappe/.local/bin
    bench init frappe-bench --frappe-branch version-15 --skip-redis-config-check
    cd frappe-bench
    bench get-app erpnext --branch version-15
    bench new-site $SITE_NAME --mariadb-root-password '$DB_ROOT_PASS' --admin-password '$ADMIN_PASS' --install-app erpnext
"

# 8. Produktionseinrichtung
echo -e "${BLUE}[6/7] Richte Produktionsmodus ein (Nginx)...${NC}"
cd /home/frappe/frappe-bench
bench setup production frappe --yes

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}   INSTALLATION ERFOLGREICH ABGESCHLOSSEN!          ${NC}"
echo -e "   URL: http://$(hostname -I | awk '{print $1}')"
echo -e "   Site: $SITE_NAME"
echo -e "   Admin-User: Administrator"
echo -e "   Admin-Passwort: $ADMIN_PASS"
echo -e "${GREEN}====================================================${NC}"
