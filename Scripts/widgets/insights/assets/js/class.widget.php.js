class WidgetInsightsJs extends CWidget {
    onInitialize() {
        super.onInitialize();
        this._analysisType = null;
        this._outputContainer = null;
        this._analyseBtn = null;
    }

    setContents(response) {
        if (!this._analysisType) {
            super.setContents(response);
            this._body.innerHTML = `
            <div class="options" style="text-align: center; margin-bottom: 20px;">
                <select id="analysisType">
                    <option value="Resumo">Resumo</option>
                    <option value="Perspectivas">Perspectivas</option>
                    <option value="Diagnóstico">Diagnóstico</option>
                    <option value="Comparação">Comparação</option>
                    <option value="Previsão">Previsão</option>
                    <option value="O que você faria?">O que você faria?</option>
                </select>
                <button id="analyseBtn">Analisar</button>
            </div>
            <div id="dashboard-container" class="dashboard-grid" style="height: 300px;">
                <div id="outputContainer" style="margin-top: 20px; border: 1px solid #ccc; padding: 10px; border-radius: 5px; background-color: #4d4a4a; box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);"></div>
            </div>
            `;

            this._analysisType = this._body.querySelector('#analysisType');
            this._outputContainer = this._body.querySelector('#outputContainer');
            this._analyseBtn = this._body.querySelector('#analyseBtn');

            this._loadHtml2Canvas().then(() => {
                this._analyseBtn.addEventListener('click', this._onAnalyseBtnClick.bind(this));
            }).catch(error => {
                console.error('Falha ao carregar html2canvas:', error);
            });
        }
    }

    _loadHtml2Canvas() {
        return new Promise((resolve, reject) => {
            if (typeof html2canvas !== 'undefined') {
                return resolve();
            }

            const script = document.createElement('script');
            script.src = 'https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js';
            script.onload = resolve;
            script.onerror = reject;
            document.head.appendChild(script);
        });
    }

    _getPromptForAnalysisType(analysisType) {
        const prompts = {
            'Resumo': "Esta imagem mostra um painel do Zabbix. Foque apenas nos dashboards dentro do painel (NÃO INCLUA o painel do AI Analyser). Forneça um resumo breve do que está sendo mostrado, focando nos pontos mais críticos e relevantes. Cores mais claras no mapa de calor indicam maior uso, cores mais escuras indicam menor uso. Sempre comece com 'Este painel mostra...' e destaque os principais pontos, sem entrar em muitos detalhes.",
            
            'Perspectivas': "Esta imagem mostra um painel do Zabbix. Foque apenas nos dashboards internos (NÃO INCLUA o painel AI Analyser). Explique o que a informação mostra e destaque qualquer insight relevante. Sempre comece com 'Este painel mostra...' e aponte padrões, tendências ou anomalias visíveis.",
            
            'Diagnóstico': "Esta imagem mostra um painel do Zabbix. Foque apenas nos dashboards internos (NÃO INCLUA o AI Analyser). Analise os dados para identificar problemas potenciais, correlações ou pontos críticos. Comece com 'Este painel mostra...' e detalhe problemas, gargalos ou falhas prováveis.",
            
            'Comparação': "Esta imagem mostra um painel do Zabbix. Foque apenas nos dashboards internos (NÃO INCLUA o AI Analyser). Compare os dados apresentados e aponte correlações, diferenças ou discrepâncias relevantes. Comece com 'Este painel mostra...' e elabore comparações claras e úteis.",
            
            'Previsão': "Esta imagem mostra um painel do Zabbix. Foque apenas nos dashboards internos (NÃO INCLUA o AI Analyser). Com base nos dados atuais, faça uma previsão das tendências de uso futuras. Comece com 'Este painel mostra...' e apresente uma análise preditiva objetiva.",
            
            'O que você faria?': "Esta imagem mostra um painel do Zabbix. Foque apenas nos dashboards internos (NÃO INCLUA o AI Analyser). Com base nos dados apresentados, sugira ações proativas que um administrador de sistemas poderia adotar. Comece com 'Com base neste painel, as ações recomendadas são:' e liste pelo menos 5 ações explicando o motivo e impacto esperado. Em seguida, proponha uma estratégia de melhoria contínua de 3 a 6 meses, com metas, métricas e sugestões de melhorias com base nos dados."
        };
        return prompts[analysisType];
    }

    async _onAnalyseBtnClick() {
        console.log("Botão de Analisar clicado...");
        const analysisType = this._analysisType.value;
        console.log("Tipo de análise selecionado:", analysisType);
        this._outputContainer.innerHTML = 'Analisando...';

        try {
            console.log("Capturando o painel...");
            const canvas = await html2canvas(document.querySelector('main'));
            const dataUrl = canvas.toDataURL('image/png');
            const base64Image = dataUrl.split(',')[1];
            const prompt = this._getPromptForAnalysisType(analysisType);

            console.log("Enviando imagem para a API Gemini...");
            const response = await fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=SUA_API_KEY', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    contents: [{
                        parts: [
                            { text: prompt },
                            {
                                inline_data: {
                                    mime_type: "image/png",
                                    data: base64Image
                                }
                            }
                        ]
                    }]
                })
            });

            const responseData = await response.json();
            console.log("Resposta da Gemini:", responseData);

            const responseContent = responseData.candidates[0].content.parts[0].text;
            this._outputContainer.innerHTML = `<div style="border: 1px solid #ccc; padding: 10px; border-radius: 5px; background-color: #4d4a4a;">${responseContent}</div>`;
        } catch (error) {
            console.error('Erro durante a análise:', error);
            this._outputContainer.innerHTML = '<div style="border: 1px solid #f00; padding: 10px; border-radius: 5px; background-color: #4d4a4a;">Ocorreu um erro durante a análise.</div>';
        }
    }
}

// Registrar o widget no Zabbix
addWidgetClass(WidgetInsightsJs);
