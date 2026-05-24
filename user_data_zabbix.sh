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

# ─── docker-compose.yml: MySQL + Zabbix Server + Zabbix Web (nginx) ──────────
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

volumes:
  mysql_data:
COMPOSE

# ─── Sobe a stack ─────────────────────────────────────────────────────────────
docker compose up -d
