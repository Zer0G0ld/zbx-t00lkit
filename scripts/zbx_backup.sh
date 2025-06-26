#!/bin/bash

# Configurações
BASE_BACKUP_DIR="/backup/zabbix"
DB_NAME="zabbix"
DB_USER="zabbix"
TMP_DB="zabbix_test_restore"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="$BASE_BACKUP_DIR/$TIMESTAMP"
MAX_ATTEMPTS=3

# Evitar erro de permissão no sudo -u postgres
cd /tmp || exit 1

# Criar diretório do backup atual
echo "📁 Criando diretório de backup: $BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"
sudo chown "$(whoami)":"$(whoami)" "$BACKUP_DIR"

BACKUP_FILE="$BACKUP_DIR/zabbix_db.sql"
CONFIG_BACKUP="$BACKUP_DIR/zabbix_config.tar.gz"
WEB_BACKUP="$BACKUP_DIR/zabbix_web.tar.gz"

attempt=1
success=false

while [ $attempt -le $MAX_ATTEMPTS ]; do
    echo "🔁 Tentativa $attempt de backup..."

    echo "📦 Realizando backup do banco de dados..."
    pg_dump -U "$DB_USER" -h localhost "$DB_NAME" > "$BACKUP_FILE"

    echo "📁 Compactando arquivos de configuração..."
    sudo tar -czf "$CONFIG_BACKUP" /etc/zabbix/ 2>/dev/null

    echo "🌐 Compactando arquivos web..."
    sudo tar -czf "$WEB_BACKUP" /usr/share/zabbix/ 2>/dev/null

    echo "🧪 Testando integridade dos arquivos..."
    if ! tar -tzf "$CONFIG_BACKUP" > /dev/null || ! tar -tzf "$WEB_BACKUP" > /dev/null; then
        echo "❌ Arquivo .tar.gz corrompido! Tentando novamente..."
        sudo rm -f "$BACKUP_FILE" "$CONFIG_BACKUP" "$WEB_BACKUP"
        attempt=$((attempt + 1))
        continue
    fi

    echo "🧬 Testando restauração do banco em $TMP_DB..."
    sudo -u postgres dropdb "$TMP_DB" --if-exists
    if sudo -u postgres createdb "$TMP_DB"; then
        if sudo -u postgres psql "$TMP_DB" < "$BACKUP_FILE" > /dev/null 2>&1; then
            echo "✅ Backup validado com sucesso!"
            sudo -u postgres dropdb "$TMP_DB"
            success=true
            break
        else
            echo "❌ Falha na restauração de teste. Tentando novamente..."
            sudo -u postgres dropdb "$TMP_DB"
        fi
    else
        echo "⚠️ Erro ao criar banco de teste. Verifique permissões do PostgreSQL."
    fi

    sudo rm -f "$BACKUP_FILE" "$CONFIG_BACKUP" "$WEB_BACKUP"
    attempt=$((attempt + 1))
done

if [ "$success" = true ]; then
    echo "🧹 Limpando backups antigos (mais de 7 dias)..."
    find "$BASE_BACKUP_DIR" -maxdepth 1 -type d -mtime +7 -exec sudo rm -rf {} \;
    echo "🎉 Backup finalizado com sucesso em $TIMESTAMP!"
    echo "📁 Todos os arquivos estão em: $BACKUP_DIR"
else
    echo "🚨 Todas as tentativas de backup falharam. Verifique os logs e permissões!"
    sudo rm -rf "$BACKUP_DIR"
fi
