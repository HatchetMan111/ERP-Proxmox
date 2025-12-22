# ERPNext 15 Proxmox Installation Script

Automatisiertes Installationsskript für ERPNext 15 auf Ubuntu 22.04/24.04 LXC Containern in Proxmox.

## Features

- ✅ Vollautomatische Installation von ERPNext 15
- ✅ Unterstützung für Ubuntu 22.04 und 24.04
- ✅ Frappe Framework Version 15
- ✅ MariaDB mit optimierter Konfiguration
- ✅ Redis für Caching
- ✅ Optional: Production Setup mit Nginx und SSL (Let's Encrypt)
- ✅ Optional: HRMS App Installation
- ✅ Interaktive Konfiguration
- ✅ Farbige Ausgabe im Stil der Proxmox Helper Scripts

## Voraussetzungen

- Proxmox VE 7.x oder 8.x
- Ubuntu 22.04 oder 24.04 LXC Container
- Mindestens 2 CPU Cores
- Mindestens 4 GB RAM
- Mindestens 20 GB Speicher

## Schnellinstallation

### Ein-Zeiler Installation

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/HatchetMan111/erpnext-proxmox-install/main/install.sh)"
```

oder mit curl:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/HatchetMan111/erpnext-proxmox-install/main/install.sh)"
```

## Manuelle Installation

1. LXC Container in Proxmox erstellen:
   - Template: Ubuntu 22.04 oder 24.04
   - CPU: 2+ Cores
   - RAM: 4096 MB
   - Disk: 20 GB
   - Netzwerk: Mit Internet-Zugang

2. Container starten und einloggen

3. Script herunterladen und ausführen:

```bash
wget https://raw.githubusercontent.com/IHR-USERNAME/erpnext-proxmox-install/main/install.sh
chmod +x install.sh
./install.sh
```

## Installationsoptionen

Das Script fragt während der Installation folgende Informationen ab:

1. **Site Name**: Der Domain-Name für Ihre ERPNext Installation (z.B. `erp.example.com`)
2. **MySQL Root Password**: Root-Passwort für die MariaDB Datenbank
3. **Admin Password**: Passwort für den ERPNext Administrator
4. **Production Setup**: 
   - `y`: Installiert Nginx als Reverse Proxy und richtet SSL ein
   - `n`: Development Setup (Zugriff über Port 8000)
5. **Let's Encrypt Email**: (nur bei Production Setup) Email für SSL Zertifikate

## Nach der Installation

### Development Setup (ohne Production)

```bash
cd /home/frappe/frappe-bench
bench start
```

Zugriff über: `http://[CONTAINER-IP]:8000`

### Production Setup

Zugriff über: `https://[SITE-NAME]`

### Wichtige Befehle

```bash
# Wechsel zum Bench Verzeichnis
cd /home/frappe/frappe-bench

# Services neustarten
bench restart

# System aktualisieren
bench update

# Backup erstellen
bench backup

# Datenbank migrieren
bench migrate

# Neue App installieren
bench get-app [APP-NAME]
bench --site [SITE-NAME] install-app [APP-NAME]

# Logs anzeigen
bench --site [SITE-NAME] console

# Supervisor Status (Production)
sudo supervisorctl status
```

## Standard Zugangsdaten

- **Benutzername**: Administrator
- **Passwort**: [Während Installation festgelegt]

## Installierte Komponenten

- **Frappe Framework**: Version 15
- **ERPNext**: Version 15
- **HRMS**: Version 15
- **MariaDB**: 10.x
- **Redis**: 6.x
- **Node.js**: 18.x
- **Python**: 3.10+
- **Nginx**: (nur bei Production Setup)

## Firewall Konfiguration

Falls Sie eine Firewall verwenden, öffnen Sie folgende Ports:

### Development Setup
- Port 8000 (HTTP)
- Port 9000 (Socketio)

### Production Setup
- Port 80 (HTTP)
- Port 443 (HTTPS)

## Proxmox LXC Konfiguration

Empfohlene Container-Einstellungen in Proxmox:

```conf
arch: amd64
cores: 2
memory: 4096
swap: 512
rootfs: local-lvm:20
net0: name=eth0,bridge=vmbr0,firewall=1,ip=dhcp
features: nesting=1
unprivileged: 1
```

## Troubleshooting

### ERPNext startet nicht

```bash
cd /home/frappe/frappe-bench
bench start
# Fehler in der Ausgabe prüfen
```

### Supervisor Probleme (Production)

```bash
sudo supervisorctl status
sudo supervisorctl restart all
sudo systemctl restart supervisor
```

### Nginx Fehler (Production)

```bash
sudo nginx -t
sudo systemctl status nginx
sudo systemctl restart nginx
```

### Datenbank Probleme

```bash
mysql -u root -p
# MariaDB Status prüfen
sudo systemctl status mariadb
```

### Permission Fehler

```bash
sudo chown -R frappe:frappe /home/frappe/frappe-bench
cd /home/frappe/frappe-bench
bench setup socketio
bench setup supervisor
sudo supervisorctl reread
sudo supervisorctl update
```

## Updates

### ERPNext updaten

```bash
cd /home/frappe/frappe-bench
bench update
```

### Manuelles Update einer App

```bash
bench update --apps [APP-NAME]
```

## Deinstallation

```bash
# Container löschen oder:
sudo systemctl stop supervisor
sudo systemctl stop nginx
sudo systemctl stop mariadb
sudo systemctl stop redis-server
sudo userdel -r frappe
sudo rm -rf /home/frappe/frappe-bench
```

## Weitere Apps

Beliebte ERPNext Apps:

```bash
cd /home/frappe/frappe-bench

# Payments App
bench get-app --branch version-15 payments
bench --site [SITE-NAME] install-app payments

# Wiki App
bench get-app --branch version-15 wiki
bench --site [SITE-NAME] install-app wiki
```

## Sicherheit

- Ändern Sie nach der Installation sofort das Administrator-Passwort
- Verwenden Sie starke Passwörter für MySQL und Admin
- Bei Production Setup: Verwenden Sie eine echte Domain und SSL
- Regelmäßige Backups erstellen: `bench backup`
- System regelmäßig aktualisieren: `apt update && apt upgrade`

## Support & Beiträge

- Issues: [GitHub Issues](https://github.com/IHR-USERNAME/erpnext-proxmox-install/issues)
- Contributions: Pull Requests willkommen!
- ERPNext Dokumentation: https://docs.erpnext.com
- Frappe Forum: https://discuss.frappe.io

## Lizenz

MIT License - siehe [LICENSE](LICENSE) Datei

## Credits

- ERPNext & Frappe: https://erpnext.com
- Inspiriert von: Proxmox Helper Scripts
- Community Scripts: https://tteck.github.io/Proxmox/

## Disclaimer

Dieses Script wird "as is" bereitgestellt. Verwendung auf eigene Gefahr. 
Immer Backups vor Systemänderungen erstellen!
