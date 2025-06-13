#!/bin/bash

# Variáveis
ZABBIX_VERSION="7.0"
DB_NAME="zabbix"
DB_USER="zabbix"
DB_PASSWORD="zabbix_pass"

echo "🚀 Iniciando instalação do Zabbix $ZABBIX_VERSION com PostgreSQL..."

# Atualiza pacotes
sudo apt update && sudo apt upgrade -y

# Instala PostgreSQL
echo "📦 Instalando PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

# Cria banco de dados e usuário
echo "🛠️ Configurando PostgreSQL..."
sudo -u postgres psql <<EOF
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE $DB_NAME OWNER $DB_USER ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' TEMPLATE template0;
ALTER USER $DB_USER WITH SUPERUSER;
EOF

# Adiciona o repositório do Zabbix
echo "📥 Adicionando repositório do Zabbix..."
wget https://repo.zabbix.com/zabbix/$ZABBIX_VERSION/debian/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VERSION}-2+debian12_all.deb
sudo dpkg -i zabbix-release_${ZABBIX_VERSION}-2+debian12_all.deb
sudo apt update

# Instala Zabbix server, frontend, agent e dependências
echo "📦 Instalando Zabbix server e componentes..."
sudo apt install -y zabbix-server-pgsql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Importa schema do banco
echo "📂 Importando schema do banco de dados..."
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u $DB_USER psql $DB_NAME

# Configurações do servidor Zabbix
echo "🧩 Configurando zabbix_server.conf..."
sudo sed -i "s/^# DBPassword=.*/DBPassword=$DB_PASSWORD/" /etc/zabbix/zabbix_server.conf

# Reinicia e ativa os serviços
echo "🔁 Iniciando serviços..."
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

echo "✅ Instalação concluída! Acesse o Zabbix Web Interface no navegador."
