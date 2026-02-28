# Documentação do Script `zbx_backup.sh` – zbx-t00lkit

## 1. Objetivo do Script

O script `zbx_backup.sh` tem como finalidade automatizar o **backup completo do Zabbix**, incluindo:

* Banco de dados PostgreSQL;
* Arquivos de configuração do Zabbix;
* Arquivos web do frontend.

O script também valida a integridade do backup, testa a restauração em um banco temporário e mantém apenas backups recentes, garantindo **redundância e confiabilidade** do sistema.

---

## 2. Pré-requisitos

Antes de executar o script, certifique-se de que:

* Sistema operacional: **Debian 12** (ou similar Linux);
* Banco de dados: **PostgreSQL** configurado com usuário e senha adequados;
* Zabbix instalado com estrutura padrão:

  * Arquivos de configuração: `/etc/zabbix/`;
  * Arquivos web: `/usr/share/zabbix/`;
* Usuário que executa o script tenha permissões de:

  * `sudo` para manipulação de diretórios e arquivos;
  * `sudo -u postgres` para manipulação do banco de dados;
* Ferramentas básicas instaladas: `tar`, `pg_dump`, `psql`, `dropdb`, `createdb`.

---

## 3. Configurações do Script

```bash
BASE_BACKUP_DIR="/backup/zabbix"     # Diretório base para armazenar backups
DB_NAME="zabbix"                      # Nome do banco de dados Zabbix
DB_USER="zabbix"                      # Usuário do PostgreSQL
TMP_DB="zabbix_test_restore"          # Banco temporário para teste de restauração
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S") # Carimbo de data/hora do backup
BACKUP_DIR="$BASE_BACKUP_DIR/$TIMESTAMP" # Diretório específico do backup atual
MAX_ATTEMPTS=3                         # Número máximo de tentativas em caso de falha
```

* **BASE_BACKUP_DIR:** Onde todos os backups serão armazenados;
* **TIMESTAMP:** Garante que cada backup seja único;
* **MAX_ATTEMPTS:** Permite retries automáticos caso haja falha na compactação ou restauração.

---

## 4. Fluxo do Script

1. **Preparação**

   * Muda para `/tmp` para evitar problemas de permissão.
   * Cria o diretório de backup atual com permissões corretas.

2. **Execução do Backup**

   * Dump do banco de dados PostgreSQL;
   * Compactação dos arquivos de configuração (`/etc/zabbix/`);
   * Compactação dos arquivos web (`/usr/share/zabbix/`).

3. **Validação**

   * Testa integridade dos arquivos `.tar.gz`;
   * Se falhar, apaga arquivos corrompidos e tenta novamente até `MAX_ATTEMPTS`.

4. **Teste de Restauração**

   * Cria banco temporário;
   * Restaura dump para validar backup;
   * Remove banco temporário após validação.

5. **Finalização**

   * Limpeza de backups antigos (>7 dias);
   * Mensagem de sucesso ou falha no final do processo.

---

## 5. Código Comentado

```bash
#!/bin/bash

# Configurações principais
BASE_BACKUP_DIR="/backup/zabbix"
DB_NAME="zabbix"
DB_USER="zabbix"
TMP_DB="zabbix_test_restore"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="$BASE_BACKUP_DIR/$TIMESTAMP"
MAX_ATTEMPTS=3

# Evitar erro de permissão sudo
cd /tmp || exit 1

# Criar diretório do backup atual
echo "📁 Criando diretório de backup: $BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"
sudo chown "$(whoami)":"$(whoami)" "$BACKUP_DIR"

# Arquivos de backup
BACKUP_FILE="$BACKUP_DIR/zabbix_db.sql"
CONFIG_BACKUP="$BACKUP_DIR/zabbix_config.tar.gz"
WEB_BACKUP="$BACKUP_DIR/zabbix_web.tar.gz"

# Inicialização de controle de tentativas
attempt=1
success=false

# Loop de backup com tentativas múltiplas
while [ $attempt -le $MAX_ATTEMPTS ]; do
    echo "🔁 Tentativa $attempt de backup..."

    # Backup do banco de dados
    echo "📦 Realizando backup do banco de dados..."
    pg_dump -U "$DB_USER" -h localhost "$DB_NAME" > "$BACKUP_FILE"

    # Compactar arquivos de configuração
    echo "📁 Compactando arquivos de configuração..."
    sudo tar -czf "$CONFIG_BACKUP" /etc/zabbix/ 2>/dev/null

    # Compactar arquivos web
    echo "🌐 Compactando arquivos web..."
    sudo tar -czf "$WEB_BACKUP" /usr/share/zabbix/ 2>/dev/null

    # Testar integridade dos arquivos
    echo "🧪 Testando integridade dos arquivos..."
    if ! tar -tzf "$CONFIG_BACKUP" > /dev/null || ! tar -tzf "$WEB_BACKUP" > /dev/null; then
        echo "❌ Arquivo .tar.gz corrompido! Tentando novamente..."
        sudo rm -f "$BACKUP_FILE" "$CONFIG_BACKUP" "$WEB_BACKUP"
        attempt=$((attempt + 1))
        continue
    fi

    # Teste de restauração do banco
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

# Finalização do backup
if [ "$success" = true ]; then
    echo "🧹 Limpando backups antigos (mais de 7 dias)..."
    find "$BASE_BACKUP_DIR" -maxdepth 1 -type d -mtime +7 -exec sudo rm -rf {} \;
    echo "🎉 Backup finalizado com sucesso em $TIMESTAMP!"
    echo "📁 Todos os arquivos estão em: $BACKUP_DIR"
else
    echo "🚨 Todas as tentativas de backup falharam. Verifique os logs e permissões!"
    sudo rm -rf "$BACKUP_DIR"
fi
```

---

## 6. Como Usar

1. Torne o script executável:

   ```bash
   chmod +x zbx_backup.sh
   ```
2. Execute o script como usuário com permissões sudo:

   ```bash
   ./zbx_backup.sh
   ```
3. Verifique mensagens de sucesso ou falha no terminal.
4. Todos os backups ficam armazenados em:

   ```
   /backup/zabbix/YYYY-MM-DD_HH-MM-SS/
   ```

---

## 7. Benefícios do Script

* Automatiza backup completo do Zabbix;
* Garante integridade do banco e arquivos;
* Permite restauração de teste para segurança;
* Mantém histórico de backups e limpa arquivos antigos;
* Funciona em terminal, sem dependência de GUI.
