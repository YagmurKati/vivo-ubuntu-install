# VIVO 1.15 Installation (Linux)

This repository packages the configs and scripts to reproduce a working VIVO 1.15 (rel-1.15-maint) install on Ubuntu with Tomcat 9.0.109 and Solr 9.6.1.

> **Heads up:** Do **not** commit live secrets. Edit `config/vivo/runtime.properties.example` locally,
copy it to the server as `/opt/vivo/vivo/config/runtime.properties`, and keep it out of git.

## Documentation
A detailed step-by-step installation guide (with screenshots) is available:

- [Installation Guide (PDF)](docs/installation-guide.pdf)

## Repository structure

```
vivo-ubuntu-install/
├─ README.md
├─ .gitignore
├─ docs/
│  └─ installation-guide.pdf
├─ config/
│  ├─ systemd/
│  │  └─ tomcat9.service
│  ├─ tomcat/
│  │  └─ setenv.sh
│  └─ vivo/
│     ├─ installer/
│     │  └─ my-settings.xml
│     └─ runtime.properties.example
└─ scripts/
   └─ bootstrap.sh
```

## Requirements
- OS: Ubuntu 22.04+ (Debian-based; adapt for other distros)
- Java: OpenJDK **17** (JDK, not JRE)
- Tomcat: **9.0.109**
- Solr: **9.6.1**
- Tools: `git`, `maven`, `curl`, `rsync`, `systemd`

## Quick start (on the target server)

```bash
# 1) Clone your repo and enter it
git clone https://github.com/YagmurKati/vivo-ubuntu-install.git
cd vivo-ubuntu-install

# 2) Run the bootstrap installer
bash scripts/bootstrap.sh

# 3) Edit live runtime config
sudo vi /opt/vivo/vivo/config/runtime.properties
# - Set Vitro.defaultNamespace to http://<HOST:PORT>/vivo/individual/
# - Set rootUser.emailAddress to your real email

# 4) Restart Tomcat
sudo systemctl restart tomcat9

# 5) Open VIVO and register with the root email, then log in
#    http://<HOST:PORT>/vivo/
```

## What this does

- Installs OpenJDK 17, Git, Maven, curl, rsync
- Installs **Apache Tomcat 9.0.109** to `/opt/tomcat9` (non-packaged) and sets it up as a systemd service
- Clones **Vitro** and **VIVO** sources (`rel-1.15-maint`), builds, and deploys `vivo.war` to Tomcat
- Creates **VIVO Home** at `/opt/vivo/vivo`
- Installs **Apache Solr 9.6.1** as a service and creates the `vivocore` using `vivo-solr` config
- Copies a sample `runtime.properties` you must edit before the final restart

## Java notes

- VIVO requires a JDK, not just a JRE. Use **OpenJDK 17**.
- If multiple JDKs exist, ensure Tomcat uses Java 17 via `config/tomcat/setenv.sh`.

## Create the admin account

With `rootUser.emailAddress` set in `runtime.properties`, any account registered with that email becomes **root admin**.
After first login, change the password and you should see **Site Admin** in the navigation.

## Files created on the machine (not committed)

- `/etc/systemd/system/tomcat9.service` — installed from this repo (systemd unit)
- `/opt/tomcat9/**` — Tomcat 9.0.109 (tarball install)
- `/opt/tomcat9/webapps/vivo/**` — deployed `vivo.war`
- `/opt/vivo/vivo/**` — VIVO_HOME (created by Maven installer)
- `/opt/vivo/vivo/config/runtime.properties` — copied from our example; **edit this**
- `/opt/solr/**` — Solr binaries (service install)
- `/var/solr/**` — Solr data and logs
- `/var/solr/data/vivocore/**` — the VIVO Solr core

**Logs**
- Tomcat: `/opt/tomcat9/logs/` (e.g., `catalina.out`)
- Solr: `/var/solr/logs/` (e.g., `solr.log`)
