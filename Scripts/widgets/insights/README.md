## 📊 Widget Insights Dashboard

O **Widget Insights Dashboard** adiciona inteligência ao seu **Zabbix Dashboard**, permitindo capturar automaticamente o painel e gerar **insights visuais com IA** (Google Gemini).  

---

### 🚀 Passo 1 – Instalação

```bash
cd /usr/share/zabbix/widgets/
sudo wget https://github.com/Zer0G0ld/zbx-t00lkit/raw/refs/heads/main/releases/insights.zip
unzip insights.zip
````

---

### 🔧 Passo 2 – Ajustar permissões

```bash
sudo chown -R www-data:www-data /usr/share/zabbix/widgets/insights
sudo chmod -R 755 /usr/share/zabbix/widgets/insights
```

> ⚠️ Substitua `www-data` pelo usuário do servidor web do Zabbix (ex.: `apache`, `nginx`, `zabbix`), caso seja diferente.

---

### 📂 Passo 3 – Estrutura de arquivos esperada

```
/usr/share/zabbix/widgets/insights/
├── assets/
│   └── js/
│       └── class.widget.php.js
├── manifest.json
└── manifest.json~
```

---

### ⚙️ Passo 4 – Configuração do widget

1. Abra o arquivo `assets/js/class.widget.php.js`
2. Localize a linha onde é feito o `fetch` para a API do Google Gemini
3. Insira sua **API Key** do Gemini
4. Salve o arquivo

---

### 📌 Passo 5 – Uso no Dashboard

1. Acesse: **Dashboard → Adicionar Widget → Insights Dashboard**
2. Selecione o tipo de análise desejada:

   * **Resumo**
   * **Diagnóstico**
   * **Comparação**
   * **Previsão**
   * **Perspectivas**
   * **“O que você faria?”**
3. Clique em **Analisar**
4. Aguarde a geração do relatório de insights

> ⏳ O tempo pode variar conforme o tamanho do dashboard e a largura de banda disponível.

---

### 🧠 Como funciona

* O widget usa **html2canvas** para capturar o painel do Zabbix
* A captura é convertida em **Base64**
* A imagem + prompt são enviados à **API Gemini**
* A resposta com os insights é exibida diretamente no widget

---
### 🔄 Fluxo do Widget Insights Dashboard

```mermaid
flowchart TD
    A[Usuário abre Dashboard] --> B[Seleciona Insights Dashboard]
    B --> C[Escolhe tipo de análise]
    C --> D[Captura do painel com html2canvas]
    D --> E[Converte imagem em Base64]
    E --> F[Envia requisição à API Gemini]
    F --> G[Recebe insights da Gemini]
    G --> H[Exibe insights no widget do Dashboard]
````