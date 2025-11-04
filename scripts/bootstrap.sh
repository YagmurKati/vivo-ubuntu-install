#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

echo "[1/8] Installing prerequisites (git, maven, openjdk-17, curl, rsync)..."
sudo apt update
sudo apt install -y git maven openjdk-17-jdk curl rsync

echo "[2/8] Creating tomcat user and layout..."
sudo useradd -r -m -U -d /opt/tomcat9 -s /bin/false tomcat || true
sudo mkdir -p /opt/tomcat9

echo "[3/8] Downloading and unpacking Tomcat 9.0.109..."
cd /tmp
curl -fLO https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.109/bin/apache-tomcat-9.0.109.tar.gz   || curl -fLO https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.109/bin/apache-tomcat-9.0.109.tar.gz
sudo tar -xzf apache-tomcat-9.0.109.tar.gz
sudo rsync -a apache-tomcat-9.0.109/ /opt/tomcat9/
sudo chown -R tomcat:tomcat /opt/tomcat9
sudo find /opt/tomcat9/bin -type f -name "*.sh" -exec sudo chmod +x {} \;

echo "[4/8] Installing systemd service and Tomcat setenv.sh..."
sudo install -m 0644 "$ROOT/config/systemd/tomcat9.service" /etc/systemd/system/tomcat9.service
sudo install -m 0755 "$ROOT/config/tomcat/setenv.sh" /opt/tomcat9/bin/setenv.sh
sudo chown tomcat:tomcat /opt/tomcat9/bin/setenv.sh
sudo systemctl daemon-reload
sudo systemctl enable --now tomcat9 || true
sudo systemctl restart tomcat9 || true

echo "[5/8] Cloning Vitro & VIVO sources (rel-1.15-maint) and building..."
sudo mkdir -p /opt/vivo
sudo chown "$USER":"$USER" /opt/vivo
cd /opt/vivo
[ -d Vitro ] || git clone https://github.com/vivo-project/Vitro.git Vitro -b rel-1.15-maint
[ -d VIVO ]  || git clone https://github.com/vivo-project/VIVO.git  VIVO  -b rel-1.15-maint

cd /opt/vivo/VIVO
mkdir -p installer
cp -f "$ROOT/config/vivo/installer/my-settings.xml" installer/my-settings.xml
mvn -q install -s installer/my-settings.xml

echo "[6/8] Ensuring VIVO Home baseline config..."
cd /opt/vivo/vivo/config
[ -f applicationSetup.n3 ] || sudo cp example.applicationSetup.n3 applicationSetup.n3
sudo chown -R tomcat:tomcat /opt/vivo/vivo

echo "[7/8] Installing Solr 9.6.1 and creating vivocore..."
cd /tmp
curl -fLO https://dlcdn.apache.org/solr/solr/9.6.1/solr-9.6.1.tgz   || curl -fLO https://archive.apache.org/dist/solr/solr/9.6.1/solr-9.6.1.tgz
tar -xzf solr-9.6.1.tgz
sudo bash solr-9.6.1/bin/install_solr_service.sh solr-9.6.1.tgz
sudo systemctl enable --now solr || true

cd /tmp
[ -d vivo-solr ] || git clone https://github.com/vivo-project/vivo-solr.git
sudo su -s /bin/bash solr -c "/opt/solr/bin/solr create -c vivocore -d /tmp/vivo-solr/vivocore/conf"

echo "[8/8] Installing runtime.properties example (edit before restart)..."
cd /opt/vivo/vivo/config
if [ ! -f runtime.properties ]; then
  sudo cp "$ROOT/config/vivo/runtime.properties.example" runtime.properties
  sudo chown tomcat:tomcat runtime.properties
  echo ">>> Edit /opt/vivo/vivo/config/runtime.properties (Vitro.defaultNamespace, rootUser.emailAddress)"
fi

echo "Restarting Tomcat and showing startup status..."
sudo systemctl restart tomcat9 || true
curl -I http://localhost:8080/vivo/ || true
curl -sS "http://localhost:8080/vivo/startupStatus?render=plaintext" | sed -n '1,80p' || true

echo "All set. Next steps:"
echo "1) Edit /opt/vivo/vivo/config/runtime.properties"
echo "2) sudo systemctl restart tomcat9"
echo "3) Visit http://<HOST:PORT>/vivo/ and register with the root email"
