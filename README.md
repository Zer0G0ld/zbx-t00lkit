# zbx-t00lkit

Repositório para armazenar e versionar templates de monitoramento para Zabbix.  
Aqui você encontra templates organizados por tipo de dispositivo para facilitar a importação e manutenção.

---

## Sobre

Este projeto nasceu para ser um backup pessoal dos meus templates, mas está aberto para quem quiser usar, colaborar, corrigir e aprimorar.  
O objetivo é ajudar a comunidade com templates úteis e fáceis de adaptar.

---

## Estrutura do repositório

```bash
zbx-t00lkit/
├── LICENSE
├── README.md
├── scripts/
│   ├── zbx_backup.sh        # Scripts para backup do Zabbix
│   └── zbx_install.sh       # Scripts para instalação/configuração automatizada
├── templates/
│   ├── Central_Telefonica/  # Templates para centrais telefônicas
│   ├── firewall/            # Templates para firewalls
│   ├── impressoras/         # Templates para impressoras (Brother, HP, etc)
│   ├── pcs/                 # Templates para estações Windows com agente Zabbix
│   └── Storage/             # Templates para dispositivos de armazenamento (ex: QNAP)

```

---

## Formatos dos templates

Cada template está disponível nos seguintes formatos para facilitar a importação no Zabbix:

- `.json` — formato JSON padrão suportado pelo Zabbix
- `.xml` — formato XML clássico para importação
- `.yaml` — formato YAML (mais legível e fácil de editar manualmente)

---

## Como usar

1. Clone o repositório:
   ```bash
   git clone https://github.com/Zer0G0ld/zbx-t00lkit.git
   ```

3. Navegue até o template desejado, por exemplo:

   ```bash
   cd zbx-t00lkit/templates/impressoras/Brother.json
   ```
4. Importe o template no Zabbix via interface web (Dados Coletados > Templates > Importar).
5. Ajuste os templates conforme sua infraestrutura.

---

## Contribuições

Contribuições são muito bem-vindas!

Para colaborar:

* Abra uma issue para sugerir melhorias ou reportar problemas.
* Faça um fork e envie um pull request com as alterações.
* Mantenha a organização da estrutura e o padrão dos arquivos.
* Descreva claramente as mudanças feitas.

---

## Ambiente usado para testes

* Sistema Operacional: Debian 12
* Versão do Zabbix: 7.0 LTS
* Banco de Dados: PostgreSQL

---

## Licença

Este projeto está licenciado sob a [GNU General Public License v3.0](./LICENSE).

---

## Contato

Caso queira trocar uma ideia ou tirar dúvidas, fique à vontade para abrir issues ou me chamar!

---

