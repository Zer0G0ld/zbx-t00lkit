#!/bin/bash

# Configurações
BACKUP_DIR="/backup/zabbix"
DB_NAME="zabbix"
DB_USER="zabbix"
TMP_DB="zabbix_test_restore"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/zabbix_db_$TIMESTAMP.sql"
CONFIG_BACKUP="$BACKUP_DIR/zabbix_config_$TIMESTAMP.tar.gz"
WEB_BACKUP="$BACKUP_DIR/zabbix_web_$TIMESTAMP.tar.gz"
MAX_ATTEMPTS=3

# Criar diretório de backup com permissões corretas
if [ ! -d "$BACKUP_DIR" ]; then
    echo "📁 Criando diretório de backup em $BACKUP_DIR..."
    sudo mkdir -p "$BACKUP_DIR"
    sudo chown $(whoami):$(whoami) "$BACKUP_DIR"
fi

attempt=1
success=false

while [ $attempt -le $MAX_ATTEMPTS ]; do
    echo "🔁 Tentativa $attempt de backup..."

    echo "📦 Realizando backup do banco de dados..."
    sudo -u postgres pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"

    echo "📁 Compactando arquivos de configuração..."
    sudo tar -czf "$CONFIG_BACKUP" /etc/zabbix/

    echo "🌐 Compactando arquivos web..."
    sudo tar -czf "$WEB_BACKUP" /usr/share/zabbix/

    echo "🧪 Testando integridade do backup..."

    # Verificar se os arquivos .tar.gz são válidos
    if ! tar -tzf "$CONFIG_BACKUP" > /dev/null || ! tar -tzf "$WEB_BACKUP" > /dev/null; then
        echo "❌ Arquivo .tar.gz corrompido! Tentando novamente..."
        rm -f "$BACKUP_FILE" "$CONFIG_BACKUP" "$WEB_BACKUP"
        attempt=$((attempt + 1))
        continue
    fi

    # Testar restauração do banco de dados
    echo "🧬 Criando banco de teste para restaurar dump..."
    sudo -u postgres dropdb "$TMP_DB" --if-exists
    if sudo -u postgres createdb "$TMP_DB"; then
        if sudo -u postgres psql "$TMP_DB" < "$BACKUP_FILE" > /dev/null 2>&1; then
            echo "✅ Backup validado com sucesso!"
            sudo -u postgres dropdb "$TMP_DB"
            success=true
            break
        else
            echo "❌ Falha ao restaurar o banco de dados. Tentando novamente..."
            sudo -u postgres dropdb "$TMP_DB"
        fi
    else
        echo "⚠️ Não foi possível criar banco de teste. Verifique permissões do PostgreSQL."
    fi

    rm -f "$BACKUP_FILE" "$CONFIG_BACKUP" "$WEB_BACKUP"
    attempt=$((attempt + 1))
done

if [ "$success" = true ]; then
    # Remover backups antigos (opcional, mantém apenas os últimos 7 dias)
    find "$BACKUP_DIR" -type f -mtime +7 -exec rm {} \;
    echo "🎉 Backup finalizado com sucesso em $TIMESTAMP!"
    echo "📁 O Backup está no sequinte diretorio $BACKUP_DIR"
else
    echo "🚨 Todas as tentativas de backup falharam. Verifique os logs e permissões!"
fi
