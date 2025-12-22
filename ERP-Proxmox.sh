#!/bin/bash

# ERPNext Installation Script for Proxmox VM (Ubuntu 22.04/24.04)
# Inspired by Proxmox Helper Scripts design
# License: MIT

set -e

# Farben für die Ausgabe
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;32m")
GN=$(echo "\033[1;32m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")

# Header
printf "${BL}
###############################################################
#                ERPNext Helper Installation                  #
#         Geeignet für Proxmox VMs (Ubuntu LTS)               #
###############################################################
${CL}\n"

# Funktions-Check: Root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RD}Fehler: Dieses Skript muss als root ausgeführt werden.${CL}"
  exit 1
fi

# Abfrage der Variablen
read -p "Gib den gewünschten Benutzernamen ein (Standard: frappe): " FRAPPE_USER
FRAPPE_USER=${FRAPPE_USER:-frappe}

read -p "Gib den Namen für die erste ERPNext-Site ein (z.B. erp.local): " SITE_NAME
SITE_NAME=${SITE_NAME:-erp.local}

read -s -p "Gib das MariaDB Root-Passwort ein: " DB_ROOT_PASS
echo ""
read -s -p "Gib das Administrator-Passwort für ERPNext ein: " ADMIN_PASS
echo ""

# 1. System Update
echo -e "${BL}1. Aktualisiere Systempakete...${CL}"
apt-get update && apt-get upgrade -y

# 2. Abhängigkeiten installieren
echo -e "${BL}2. Installiere Abhängigkeiten (Python, Redis, Git, etc.)...${CL}"
apt-get install -y git python3-dev python3-pip python3-venv \
    software-properties-common mariadb-server mariadb-client \
    redis-server wget curl cron sudo libssl-dev \
    pkg-config libmysqlclient-dev

# 3. MariaDB Konfiguration (Optimierung für ERPNext)
echo -e "${BL}3. Konfiguriere MariaDB...${CL}"
cat <<EOF > /etc/mysql/mariadb.conf.d/erpnext.cnf
[server]
user = mysql
pid-file = /run/mysqld/mysqld.pid
socket = /run/mysqld/mysqld.sock
basedir = /usr
datadir = /var/lib/mysql
tmpdir = /tmp
lc-messages-dir = /usr/share/mysql
bind-address = 127.0.0.1
query_cache_size = 16M
log_error = /var/log/mysql/error.log

[mysqld]
innodb-check-optimize-helper
innodb_file_per_table = 1
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOF

systemctl restart mariadb

# MariaDB Root Passwort setzen
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASS';"
mysql -u root -p"$DB_ROOT_PASS" -e "DELETE FROM mysql.user WHERE User='';"
mysql -u root -p"$DB_ROOT_PASS" -e "FLUSH PRIVILEGES;"

# 4. Node.js & Yarn
echo -e "${BL}4. Installiere Node.js & Yarn...${CL}"
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs
npm install -g yarn

# 5. Frappe Benutzer anlegen
echo -e "${BL}5. Erstelle Benutzer '$FRAPPE_USER'...${CL}"
useradd -m -s /bin/bash $FRAPPE_USER
usermod -aG sudo $FRAPPE_USER
echo "$FRAPPE_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 6. Frappe-Bench Installation
echo -e "${BL}6. Installiere Frappe-Bench...${CL}"
pip3 install frappe-bench

# 7. Bench initialisieren & ERPNext Setup
echo -e "${BL}7. Initialisiere Bench & installiere ERPNext (Dies kann dauern)...${CL}"
su - $FRAPPE_USER <<EOF
export PATH=\$PATH:/home/$FRAPPE_USER/.local/bin
bench init frappe-bench --frappe-branch version-15
cd frappe-bench
bench get-app erpnext --branch version-15
bench new-site $SITE_NAME --mariadb-root-password "$DB_ROOT_PASS" --admin-password "$ADMIN_PASS" --install-app erpnext
EOF

# 8. Produktionseinrichtung (Nginx & Supervisor)
echo -e "${BL}8. Konfiguriere Produktionsmodus (Nginx/Supervisor)...${CL}"
cd /home/$FRAPPE_USER/frappe-bench
sudo bench setup production $FRAPPE_USER --yes

# Abschluss
echo -e "${GN}###############################################################${CL}"
echo -e "${GN} INSTALLATION ABGESCHLOSSEN ${CL}"
echo -e "${DGN} Site: http://$(hostname -I | awk '{print $1}')${CL}"
echo -e "${DGN} Administrator Passwort: $ADMIN_PASS ${CL}"
echo -e "${GN}###############################################################${CL}"
