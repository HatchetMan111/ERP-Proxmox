# ERPNext 15 - Proxmox Installation Script

Automatisches Installationsskript für ERPNext 15 auf Ubuntu 22.04/24.04 LXC Containern in Proxmox VE im Stil der Community Helper Scripts.

Dieses Script installiert ERPNext 15 (inkl. Frappe Framework & HRMS) komplett automatisiert mit allen notwendigen Dependencies: MariaDB, Redis, Node.js, Nginx und optional SSL via Let's Encrypt.

## 🚀 Schnellinstallation

### Empfohlene Methode (wget):

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/HatchetMan111/ERP-Proxmox/main/install.sh)"
```

### Alternative Methode (curl):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/HatchetMan111/ERP-Proxmox/main/install.sh)
```

## ✨ Features

- ✅ **Vollautomatische Installation** - Ein Befehl, fertig!
- ✅ **Frappe Framework 15** - Neueste Version
- ✅ **ERPNext 15** - Enterprise Resource Planning
- ✅ **HRMS App** - Human Resource Management
- ✅ **MariaDB** - Optimierte Datenbank-Konfiguration
- ✅ **Redis** - High-Performance Caching
- ✅ **Node.js 18** - Moderne JavaScript Runtime
- ✅ **Production Ready** - Optional mit Nginx & SSL
- ✅ **Let's Encrypt SSL** - Kostenlose SSL-Zertifikate
- ✅ **Interaktive Konfiguration** - Einfache Setup-Dialoge
- ✅ **Farbige Ausgabe** - Übersichtliche Installation

## 📋 Voraussetzungen

### Minimale LXC Container Anforderungen:

- ✅ **OS**: Ubuntu 22.04 oder 24.04
- ✅ **CPU**: 2+ Cores empfohlen (Minimum: 2)
- ✅ **RAM**: 4096 MB empfohlen (Minimum: 2048 MB)
- ✅ **Disk**: 20 GB empfohlen (Minimum: 10 GB)
- ✅ **Netzwerk**: Zugang zum Internet
- ✅ **Root-Zugriff**: Erforderlich

### Empfohlene Proxmox LXC Konfiguration:

```bash
# Container erstellen in Proxmox Web UI:
# CT ID: [Ihre Wahl]
# Template: Ubuntu 22.04 oder 24.04
# Disk: 20 GB
# CPU: 2 Cores
# Memory: 4096 MB
# Swap: 512 MB
# Network: vmbr0 mit DHCP oder statischer IP
# Features: Nesting aktivieren (für bessere Kompatibilität)
```

Oder per CLI:

```bash
pct create 100 local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst \
  --hostname erpnext \
  --cores 2 \
  --memory 4096 \
  --swap 512 \
  --rootfs local-lvm:20 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --features nesting=1 \
  --unprivileged 1
```

## 🎯 Installation

### Schritt 1: LXC Container vorbereiten

1. In Proxmox: Container erstellen (siehe Voraussetzungen)
2. Container starten
3. Als root einloggen

### Schritt 2: Script ausführen

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/HatchetMan111/ERP-Proxmox/main/install.sh)"
```

### Schritt 3: Konfiguration eingeben

Das Script fragt folgende Informationen ab:

1. **Site Name**: Domain für ERPNext (z.B. `erp.example.com` oder `erp.local`)
2. **MySQL Root Password**: Sicheres Passwort für MariaDB
3. **ERPNext Admin Password**: Passwort für Administrator-Account
4. **Production Setup**: 
   - `y` → Nginx + SSL (empfohlen für Produktiv-Umgebungen)
   - `n` → Development Mode (Port 8000)
5. **Let's Encrypt Email**: (nur bei Production) Email für SSL-Benachrichtigungen

### Schritt 4: Warten & Genießen ☕

Die Installation dauert ca. 15-20 Minuten. Das Script:
- Installiert alle Dependencies
- Konfiguriert MariaDB & Redis
- Initialisiert Frappe Bench
- Installiert ERPNext & HRMS
- Richtet Nginx ein (optional)
- Konfiguriert SSL (optional)

## 🎮 Nach der Installation

### Development Setup (Port 8000)

Wenn Sie Development Mode gewählt haben:

```bash
# Zum Bench Verzeichnis wechseln
cd /home/frappe/frappe-bench

# Server starten
bench start
```

**Zugriff**: `http://[CONTAINER-IP]:8000`

### Production Setup (Nginx)

Wenn Sie Production Mode gewählt haben:

**Zugriff**: `https://[IHRE-DOMAIN]` oder `http://[CONTAINER-IP]`

Services laufen automatisch im Hintergrund.

## 🔐 Login Daten

- **URL**: Siehe oben je nach Setup
- **Benutzername**: `Administrator`
- **Passwort**: [Von Ihnen während Installation festgelegt]

## 📚 Wichtige Befehle

### Basis-Befehle

```bash
# Zum Bench Verzeichnis
cd /home/frappe/frappe-bench

# Services neustarten (Production)
bench restart

# System aktualisieren
bench update

# Backup erstellen
bench backup

# Datenbank migrieren
bench migrate

# Bench Status
bench --version
```

### App Management

```bash
# Neue App installieren
bench get-app [APP-NAME]
bench --site [SITE-NAME] install-app [APP-NAME]

# Installierte Apps anzeigen
bench --site [SITE-NAME] list-apps

# App entfernen
bench --site [SITE-NAME] uninstall-app [APP-NAME]
```

### Site Management

```bash
# Neue Site erstellen
bench new-site [SITE-NAME]

# Sites auflisten
bench --site all list

# Site löschen
bench drop-site [SITE-NAME]
```

### Logs & Debugging

```bash
# Logs ansehen (Development)
cd /home/frappe/frappe-bench
bench --site [SITE-NAME] console

# Supervisor Status (Production)
sudo supervisorctl status

# Nginx Logs (Production)
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Bench Logs
tail -f logs/web.error.log
tail -f logs/worker.error.log
```

## 🔧 Troubleshooting

### Service startet nicht

```bash
# Prüfen ob alle Services laufen
sudo systemctl status nginx
sudo systemctl status mariadb
sudo systemctl status redis-server
sudo supervisorctl status all

# Services neustarten
sudo systemctl restart nginx
sudo systemctl restart mariadb
sudo supervisorctl restart all
```

### Permission Fehler

```bash
# Rechte korrigieren
sudo chown -R frappe:frappe /home/frappe/frappe-bench

# Supervisor neu konfigurieren
cd /home/frappe/frappe-bench
bench setup supervisor
sudo supervisorctl reread
sudo supervisorctl update
```

### Nginx Konfiguration prüfen

```bash
# Nginx Syntax prüfen
sudo nginx -t

# Nginx neustarten
sudo systemctl restart nginx
```

### Datenbank Probleme

```bash
# Als root in MySQL
mysql -u root -p

# MariaDB neu konfigurieren
sudo systemctl restart mariadb
```

### Port bereits belegt

```bash
# Prüfen welcher Prozess Port 8000 nutzt
sudo lsof -i :8000

# Prozess beenden und neu starten
cd /home/frappe/frappe-bench
bench restart
```

## 🔄 Updates & Upgrades

### ERPNext updaten

```bash
cd /home/frappe/frappe-bench
bench update
```

### Einzelne App updaten

```bash
bench update --apps erpnext
bench update --apps hrms
```

### System-Packages updaten

```bash
sudo apt update
sudo apt upgrade -y
```

## 🌐 Zusätzliche Apps installieren

### Beliebte ERPNext Apps:

```bash
cd /home/frappe/frappe-bench

# Payments App
bench get-app --branch version-15 payments
bench --site [SITE-NAME] install-app payments

# Wiki App
bench get-app --branch version-15 wiki
bench --site [SITE-NAME] install-app wiki

# Helpdesk App
bench get-app --branch version-15 helpdesk
bench --site [SITE-NAME] install-app helpdesk
```

## 🔒 Sicherheit

### Empfohlene Sicherheitsmaßnahmen:

1. **Starke Passwörter** verwenden
2. **SSH Key Authentication** einrichten
3. **Firewall konfigurieren**:
   ```bash
   # UFW installieren
   apt install ufw
   
   # Ports öffnen
   ufw allow 22/tcp    # SSH
   ufw allow 80/tcp    # HTTP
   ufw allow 443/tcp   # HTTPS
   
   # Firewall aktivieren
   ufw enable
   ```
4. **Regelmäßige Backups**:
   ```bash
   # Automatische tägliche Backups einrichten
   crontab -e
   # Folgende Zeile hinzufügen:
   0 2 * * * cd /home/frappe/frappe-bench && bench backup
   ```
5. **System-Updates**: `apt update && apt upgrade` regelmäßig ausführen

## 📱 Zugriff von außerhalb

### Port Forwarding in Proxmox

Wenn Sie von außerhalb des Netzwerks zugreifen möchten:

1. **Router**: Port 80 und 443 auf Container-IP weiterleiten
2. **Domain**: A-Record auf öffentliche IP setzen
3. **SSL**: Let's Encrypt wird automatisch konfiguriert (bei Production Setup)

## 🗄️ Backup & Restore

### Backup erstellen

```bash
cd /home/frappe/frappe-bench

# Backup mit Dateien
bench --site [SITE-NAME] backup --with-files

# Backups finden sich in:
ls -lh sites/[SITE-NAME]/private/backups/
```

### Backup wiederherstellen

```bash
# Datenbank wiederherstellen
bench --site [SITE-NAME] --force restore [BACKUP-FILE].sql.gz

# Mit Dateien
bench --site [SITE-NAME] --force restore [BACKUP-FILE].sql.gz --with-private-files [FILES-BACKUP].tar --with-public-files [PUBLIC-FILES].tar
```

### Automatische Backups

```bash
# Backup-Script erstellen
sudo nano /usr/local/bin/erpnext-backup.sh
```

Inhalt:
```bash
#!/bin/bash
cd /home/frappe/frappe-bench
bench --site all backup --with-files
find sites/*/private/backups/ -name "*.gz" -mtime +7 -delete
```

Ausführbar machen und Cronjob einrichten:
```bash
sudo chmod +x /usr/local/bin/erpnext-backup.sh
sudo crontab -e
# Fügen Sie hinzu (tägliches Backup um 2 Uhr nachts):
0 2 * * * /usr/local/bin/erpnext-backup.sh
```

## 💡 Performance-Tipps

### MariaDB optimieren

```bash
sudo nano /etc/mysql/mariadb.conf.d/50-erpnext.cnf
```

Für 4GB RAM Container:
```ini
[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
max_connections = 200
```

### Redis optimieren

```bash
sudo nano /etc/redis/redis.conf
```

Ändern:
```ini
maxmemory 512mb
maxmemory-policy allkeys-lru
```

## 📊 Monitoring

### System-Ressourcen überwachen

```bash
# CPU & RAM
htop

# Disk Space
df -h

# Disk I/O
iotop

# Network
iftop
```

### ERPNext Logs

```bash
cd /home/frappe/frappe-bench
tail -f logs/*.log
```

## 🆘 Support & Community

- **ERPNext Forum**: https://discuss.frappe.io
- **Dokumentation**: https://docs.erpnext.com
- **GitHub Issues**: [Issues](https://github.com/HatchetMan111/ERP-Proxmox/issues)
- **Frappe GitHub**: https://github.com/frappe

## 🤝 Contributing

Beiträge sind willkommen! 

1. Fork das Repository
2. Feature Branch erstellen
3. Änderungen commiten
4. Pull Request öffnen

Siehe auch: [CONTRIBUTING.md](CONTRIBUTING.md)

## 📝 Lizenz

MIT License - siehe [LICENSE](LICENSE)

## 🙏 Credits

- **ERPNext & Frappe**: https://erpnext.com
- **Proxmox Helper Scripts**: https://community-scripts.github.io/ProxmoxVE/
- **Community Scripts Projekt**: Original Scripts von tteck

## ⚠️ Disclaimer

Dieses Script wird "as is" bereitgestellt ohne jegliche Garantie. 
Verwendung auf eigene Gefahr. Immer Backups vor Systemänderungen erstellen!

---

Made with ❤️ für die Proxmox Community
