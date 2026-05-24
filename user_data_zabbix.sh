#!/bin/bash
set -e

# ─── Atualização do sistema ───────────────────────────────────────────────────
dnf update -y

# ─── Swap de 2GB (t3.micro só tem 1GB de RAM) ────────────────────────────────
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# ─── Instalação do Docker ─────────────────────────────────────────────────────
dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# ─── Docker Compose plugin (v2) ──────────────────────────────────────────────
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# ─── Diretório do Zabbix ──────────────────────────────────────────────────────
mkdir -p /opt/zabbix
cd /opt/zabbix

# ─── docker-compose.yml: MySQL + Zabbix Server + Zabbix Web (nginx) + Agent ──
cat > docker-compose.yml <<'COMPOSE'
services:
  mysql:
    image: mysql:8.0-oracle
    restart: always
    environment:
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbix_pwd
      MYSQL_ROOT_PASSWORD: root_pwd
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_bin
    volumes:
      - mysql_data:/var/lib/mysql

  zabbix-server:
    image: zabbix/zabbix-server-mysql:alpine-7.0-latest
    restart: always
    depends_on:
      - mysql
    environment:
      DB_SERVER_HOST: mysql
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbix_pwd
      MYSQL_ROOT_PASSWORD: root_pwd
    ports:
      - "10051:10051"

  zabbix-web:
    image: zabbix/zabbix-web-nginx-mysql:alpine-7.0-latest
    restart: always
    depends_on:
      - mysql
      - zabbix-server
    environment:
      ZBX_SERVER_HOST: zabbix-server
      DB_SERVER_HOST: mysql
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbix_pwd
      MYSQL_ROOT_PASSWORD: root_pwd
      PHP_TZ: America/Sao_Paulo
    ports:
      - "80:8080"

  zabbix-agent:
    image: zabbix/zabbix-agent2:alpine-7.0-latest
    restart: always
    depends_on:
      - zabbix-server
    environment:
      ZBX_SERVER_HOST: zabbix-server
      ZBX_HOSTNAME: "Zabbix server"
    privileged: true

volumes:
  mysql_data:
COMPOSE

# ─── Sobe a stack ─────────────────────────────────────────────────────────────
docker compose up -d

# ─── Script para corrigir a interface do host "Zabbix server" via API ────────
# O host padrão aponta para 127.0.0.1 que não funciona dentro do Docker.
# Este script aguarda a API ficar disponível e atualiza para o hostname do container.
cat > /opt/zabbix/fix-zabbix-host.sh <<'SCRIPT'
#!/bin/bash

API="http://localhost/api_jsonrpc.php"
MAX_WAIT=300
ELAPSED=0

echo "[fix-zabbix-host] Aguardando API do Zabbix..."
until [ "$(curl -s -o /dev/null -w '%{http_code}' "$API")" = "200" ]; do
  sleep 10
  ELAPSED=$((ELAPSED + 10))
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "[fix-zabbix-host] Timeout aguardando API. Abortando."
    exit 1
  fi
done

echo "[fix-zabbix-host] API disponível. Obtendo token..."
TOKEN=$(curl -s -X POST "$API" \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"user.login","params":{"username":"Admin","password":"zabbix"},"id":1}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',''))")

if [ -z "$TOKEN" ]; then
  echo "[fix-zabbix-host] Falha ao obter token. Abortando."
  exit 1
fi

echo "[fix-zabbix-host] Token obtido. Buscando interface com IP 127.0.0.1..."
INTERFACE_ID=$(curl -s -X POST "$API" \
  -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"hostinterface.get\",\"params\":{\"output\":\"extend\",\"filter\":{\"ip\":\"127.0.0.1\"}},\"auth\":\"$TOKEN\",\"id\":2}" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['interfaceid']) if d.get('result') else print('')")

if [ -z "$INTERFACE_ID" ]; then
  echo "[fix-zabbix-host] Interface 127.0.0.1 não encontrada (já corrigida?)."
  exit 0
fi

echo "[fix-zabbix-host] Atualizando interface $INTERFACE_ID para DNS: zabbix-agent..."
curl -s -X POST "$API" \
  -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"hostinterface.update\",\"params\":{\"interfaceid\":\"$INTERFACE_ID\",\"useip\":0,\"dns\":\"zabbix-agent\",\"ip\":\"\"},\"auth\":\"$TOKEN\",\"id\":3}"

echo ""
echo "[fix-zabbix-host] Concluído."
SCRIPT

chmod +x /opt/zabbix/fix-zabbix-host.sh

# ─── Systemd unit para rodar a correção uma vez após o boot ──────────────────
cat > /etc/systemd/system/fix-zabbix-host.service <<'UNIT'
[Unit]
Description=Corrige interface do host Zabbix server para apontar ao container do agente
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/opt/zabbix/fix-zabbix-host.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable fix-zabbix-host.service
systemctl start fix-zabbix-host.service
