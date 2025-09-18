var Gemini = {
    params: {},
    setParams: function(params) {
        if (typeof params !== 'object') return;
        Gemini.params = params;
        if (typeof Gemini.params.api_key !== 'string' || Gemini.params.api_key === '') {
            throw 'A chave de API do Gemini é obrigatória.';
        }
        Gemini.params.url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
    },
    request: function(data) {
        if (!Gemini.params.api_key) {
            throw 'Chave de API ausente.';
        }
        var request = new HttpRequest();
        request.addHeader('Content-Type: application/json');

        var urlComChave = Gemini.params.url + '?key=' + Gemini.params.api_key;

        Zabbix.log(4, '[ Gemini Webhook ] Enviando requisição: ' + urlComChave + '\n' + JSON.stringify(data));
        var response = request.post(urlComChave, JSON.stringify(data));
        Zabbix.log(4, '[ Gemini Webhook ] Resposta recebida com status ' + request.getStatus() + '\n' + response);

        if (request.getStatus() < 200 || request.getStatus() >= 300) {
            throw 'Falha na requisição para a API do Gemini. Código de status: ' + request.getStatus() + '.';
        }

        try {
            response = JSON.parse(response);
        } catch (error) {
            Zabbix.log(4, '[ Gemini Webhook ] Falha ao interpretar resposta da Gemini.');
            response = null;
        }
        return response;
    }
};

try {
    var params = JSON.parse(value),
        data = {},
        resultado = "",
        parametros_obrigatorios = ['alert_subject'];

    Object.keys(params).forEach(function(chave) {
        if (parametros_obrigatorios.indexOf(chave) !== -1 && params[chave] === '') {
            throw 'O parâmetro "' + chave + '" não pode estar vazio.';
        }
    });

    data = {
        contents: [{
            parts: [{
                text: "Alerta: " + params.alert_subject + " detectado no Zabbix. " +
                      "Sugira possíveis causas e soluções para esse problema. Responda de forma direta, com até 10 linhas contendo ideias, comandos para depuração e ações para evitar recorrência."
            }]
        }]
    };

    Gemini.setParams({ api_key: params.api_key });

    var response = Gemini.request(data);

    if (response && response.candidates && response.candidates.length > 0) {
        resultado = response.candidates[0].content.parts[0].text.trim();
    } else {
        throw 'Nenhuma resposta recebida da Gemini.';
    }

    return resultado;

} catch (erro) {
    Zabbix.log(3, '[ Gemini Webhook ] ERRO: ' + erro);
    throw 'Envio falhou: ' + erro;
}