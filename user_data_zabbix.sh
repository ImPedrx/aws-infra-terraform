#!/bin/bash
set -e

# ─── Atualização do sistema ───────────────────────────────────────────────────
dnf update -y

# ─── Repositório oficial Zabbix 7.0 (Amazon Linux 2023) ──────────────────────
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/amazonlinux/2023/x86_64/zabbix-release-latest-7.0.amzn2023.noarch.rpm
dnf clean all

# ─── Instalação: Zabbix Server + Frontend + Agent ────────────────────────────
dnf install -y \
  zabbix-server-mysql \
  zabbix-web-mysql \
  zabbix-apache-conf \
  zabbix-sql-scripts \
  zabbix-selinux-policy \
  zabbix-agent2

# ─── Instalação: MariaDB ──────────────────────────────────────────────────────
dnf install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb

# ─── Criação do banco de dados Zabbix ────────────────────────────────────────
mysql -uroot <<'SQL'
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
SQL

# ─── Importação do schema inicial ────────────────────────────────────────────
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | \
  mysql --default-character-set=utf8mb4 -uzabbix -p123456 zabbix

# ─── Desativa log_bin_trust_function_creators após importação ─────────────────
mysql -uroot -e "SET GLOBAL log_bin_trust_function_creators = 0;"

# ─── Configura senha do banco no Zabbix Server ───────────────────────────────
sed -i 's/# DBPassword=/DBPassword=123456/' /etc/zabbix/zabbix_server.conf

# ─── Configura timezone para o frontend (Brasil) ─────────────────────────────
sed -i 's/# php_value date.timezone Europe\/Riga/php_value date.timezone America\/Sao_Paulo/' \
  /etc/httpd/conf.d/zabbix.conf

# ─── Inicia e habilita todos os serviços ─────────────────────────────────────
systemctl restart zabbix-server zabbix-agent2 httpd php-fpm
systemctl enable  zabbix-server zabbix-agent2 httpd php-fpm
