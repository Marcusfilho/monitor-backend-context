\# CONTEXT — Monitor Backend + SchemeBuilder Worker (Render + VM + Host Chrome)



> Objetivo do projeto: ter um \*\*APP/Backend/Worker\*\* estável para automatizar \*\*Assign Setting + Scheme Builder\*\* via \*\*WebSocket do Traffilog\*\*, com fila de jobs no backend (Render) e execução no worker (VM), usando credenciais capturadas no \*\*Chrome normal da Host\*\*.



---



\## 1) Premissas (NUNCA esquecer)

\- \*\*O Monitor (UI) não exibe token/cookie/infos críticas\*\* para debug/integração.

\- Para operar o WS, precisamos capturar:

&nbsp; - \*\*WS Request URL\*\* (contém GUID + TOKEN na URL)

&nbsp; - \*\*Origin\*\* do WS

&nbsp; - (às vezes) \*\*Cookie\*\* ou outros headers que a UI usa

\- \*\*Não queremos abrir Chrome em modo debug\*\*.

\- Fluxo desejado no final:

&nbsp; 1) Abrir o \*\*Monitor na Host (Chrome normal)\*\*

&nbsp; 2) Rodar \*\*um script no Console\*\* que captura token/cookie/WS URL

&nbsp; 3) Enviar isso para o \*\*backend no Render\*\*

&nbsp; 4) A \*\*VM (worker)\*\* apenas roda e consome jobs do Render, sem “colar coisa” manualmente na VM.



---



\## 2) Arquitetura (como as peças se conectam)

\### Componentes

\- \*\*Host (Windows + Chrome normal)\*\*

&nbsp; - Onde o Monitor (operation.traffilog.com) está logado.

&nbsp; - Executa script de captura (Console) para extrair:

&nbsp;   - WS URL (com GUID/TOKEN)

&nbsp;   - Origin

&nbsp;   - Cookie (se necessário)

&nbsp; - Envia para o \*\*Render\*\* (HTTP POST) para armazenamento.



\- \*\*Backend (Render)\*\*

&nbsp; - Expõe endpoints:

&nbsp;   - \*\*/api/jobs\*\* (fila / status)

&nbsp;   - \*\*/api/scheme-builder/start\*\* (cria job)

&nbsp;   - Rotas “admin” (quando existirem) para salvar token/cookie e/ou consultar estado.

&nbsp; - Armazena “credenciais de sessão” (token/cookie/ws\_url) para os workers usarem.



\- \*\*Worker (VM Ubuntu — systemd service)\*\*

&nbsp; - Fica “ouvindo” o backend (poll/ACK) e executa jobs.

&nbsp; - Abre WebSocket com `websocket.traffilog.com:8182` usando os dados capturados.



---



\## 3) Informações críticas do WebSocket (descobertas)

\- O WS do Traffilog aparece como:

&nbsp; - `wss://websocket.traffilog.com:8182/<GUID>/<TOKEN>/json?defragment=1`

\- No \*\*net-export (chrome://net-export)\*\*:

&nbsp; - WS aparece com GET `/GUID/TOKEN/json?defragment=1`

&nbsp; - \*\*Origin = https://operation.traffilog.com\*\*

&nbsp; - Pode não aparecer `Cookie` no handshake (autenticação pode estar no TOKEN da URL).

\- Opções importantes do net-export:

&nbsp; - \*\*Include cookies and credentials = ON\*\*

&nbsp; - \*\*Strip private information = OFF\*\*

\- Conclusão prática:

&nbsp; - Precisamos capturar e persistir pelo menos `WS\_URL` e `Origin`.

&nbsp; - Cookie é “caso a caso”: se houver timeout/403/404, reavaliar necessidade.



---



\## 4) Ferramentas / scripts que já usamos

\### 4.1 Sniffer (Host Chrome Console)

\- \*\*Sniffer SB2-SEND (WS amplo)\*\*:

&nbsp; - Hook em `WebSocket.prototype.send`

&nbsp; - Filtra por chaves (vehicle\_id, action\_id, review/execute/associate etc.)

&nbsp; - Decodifica `%...` com `decodeURIComponent` e tenta `JSON.parse`

&nbsp; - Loga `ws\_url`, `action.name`, `flow\_id`, `root\_keys/param\_keys`,

&nbsp;   `vehicle\_id/action\_id/process\_id/unit\_key/inner\_id` + `sample\_dec`

\- \*\*Fallback\*\*: Sniffer via `window.fetch` e `XMLHttpRequest` para capturar execuções que não passam pelo WS.



> Esses sniffers foram salvos como referência para futuras automações além do SchemeBuilder.



\### 4.2 Net-export (Host)

\- Método validado para capturar handshake do WS sem modo debug:

&nbsp; - `chrome://net-export` → gerar log

&nbsp; - Encontrar WS para `websocket.traffilog.com:8182` e copiar `Request URL`



\### 4.3 VM (worker side) — execução local

\- Script utilitário:

&nbsp; - `tools/run\_sb\_vm.sh` (invoca `node tools/sb\_run\_vm.js ...`)

\- Script principal:

&nbsp; - `tools/sb\_run\_vm.js`

&nbsp; - Faz handshake WS, manda frames, espera respostas por mtkn e executa sequência (Assign + Review + Execute).



---



\## 5) Variáveis de ambiente (padrões)

> (nomes podem variar conforme versão; manter estes como referência)



\- `MONITOR\_SESSION\_TOKEN`  

&nbsp; Token/sessão que entra na WS\_URL (quando aplicável).



\- `MONITOR\_WS\_URL`  

&nbsp; Ex: `wss://websocket.traffilog.com:8182/<GUID>/<TOKEN>/json?defragment=1`



\- `MONITOR\_WS\_ORIGIN`  

&nbsp; Normalmente: `https://operation.traffilog.com`



\- `MONITOR\_WS\_COOKIE`  

&nbsp; Se necessário (nem sempre aparece no net-export; usar apenas se for comprovadamente necessário).



\- `MONITOR\_WS\_PROTOCOL`  

&nbsp; Se o servidor exigir subprotocol; caso contrário pode ficar vazio.



\- `WS\_PASSWORD` / `MONITOR\_PASSWORD\_FILE`  

&nbsp; Estratégia para senha (preferência atual: manter seguro e consistente; evitar exportar “bagunçado” em arquivos sem necessidade).



\- Worker:

&nbsp; - `JOB\_SERVER\_BASE\_URL` (Render ou local)

&nbsp; - `WORKER\_ID`

&nbsp; - `BASE\_POLL\_INTERVAL\_MS`

&nbsp; - `WS\_WAIT\_TIMEOUT\_MS` (timeout de espera de resposta WS)



---



\## 6) Principais problemas enfrentados e correções aplicadas

\### 6.1 Timeout / “mtkn não retorna”

Sintomas:

\- Worker fica em `processing` por muito tempo

\- Erro: timeout aguardando resposta do WS (ex.: 30s ou 3min inesperados)



Correções aplicadas:

\- Ajustes de parsing de resposta WS para reconhecer:

&nbsp; - `response.properties.mtkn` (formato `action\_value`)

&nbsp; - além de formatos antigos com `row/process\_id`

\- Ajustes para extrair `process\_id` quando o `review` retorna `data\[]`:

&nbsp; - Fallbacks para pegar `process\_id` dentro de `response.properties.data\[]`



Observação importante:

\- Em um momento, o timeout esperado era \*\*15s\*\*, mas ficou \*\*30000ms / 3min\*\* por regressão.

&nbsp; - Reforço: manter `WS\_WAIT\_TIMEOUT\_MS` coerente e fácil de auditar.



\### 6.2 Sequência correta: associate → process\_id → review

A correção-chave recente foi garantir que:

\- `mtknReview` (get\_vcls\_action\_review\_opr) seja disparado \*\*após\*\*:

&nbsp; - `associate\_vehicles\_actions\_opr` retornar `process\_id`

\- Foi inserida/planejada uma função tipo `extractProcessId()` para padronizar isso.



Resultado esperado:

\- “review/associate” ficam consistentes e não entram em race condition.



\### 6.3 “Cache” / worker pegando código antigo

Sintomas:

\- Após alterar arquivos e fazer build, o worker parece rodar “versão antiga”.



Checklist operacional:

\- Confirmar `npm run build` sem erro (dist atualizado)

\- Confirmar `systemctl restart monitor-schemebuilder-worker`

\- Conferir logs com:

&nbsp; - `journalctl -u monitor-schemebuilder-worker -n 200 --no-pager -o cat`

\- Garantir que o systemd service aponta para o \*\*node correto\*\* e para o \*\*arquivo dist correto\*\*

\- Verificar se há dois services/overrides conflitando (ex.: override antigo mantendo path antigo)



---



\## 7) Estado atual do projeto (última posição conhecida)

\- Já conseguimos:

&nbsp; - Capturar WS URL por net-export

&nbsp; - Rodar `sb\_run\_vm.js` e abrir WS com sucesso

&nbsp; - Enviar frames e receber mensagens `action\_value`

&nbsp; - Avançar no fluxo até \*\*associate → process\_id → review\*\* após patches

\- Ainda pendente / em validação:

&nbsp; - Confirmar definitivamente se \*\*Cookie\*\* é necessário no handshake

&nbsp; - Consolidar o “store” de token/ws\_url no Render para não depender de export manual na VM

&nbsp; - Garantir que timeouts (15s) não regredem ao ajustar parsing

&nbsp; - Limpar duplicidades/strings antigas no `sb\_run\_vm.js` (cleanup pendente)



---



\## 8) Comandos úteis (VM)

> Ajuste `BASE` conforme seu Render.



\### 8.1 Build + restart

\- `npm run build`

\- `sudo systemctl restart monitor-schemebuilder-worker`

\- `sudo journalctl -u monitor-schemebuilder-worker -n 200 --no-pager -o cat`



\### 8.2 Teste rápido por script (VM)

\- `node tools/sb\_run\_vm.js <clientId> <clientName> <vehicleId> <vehicleSettingId> "<comment>"`



\### 8.3 Verificar env do processo (quando necessário)

\- (com PID do service)

\- `sudo tr '\\0' '\\n' < /proc/$PID/environ | grep -E '^(MONITOR\_WS\_URL|MONITOR\_WS\_COOKIE|MONITOR\_WS\_ORIGIN|MONITOR\_WS\_PROTOCOL)='`



---



\## 9) Padrões e preferências do repo

\- Busca padrão: `grep -RIn --exclude-dir=node\_modules --exclude-dir=dist ...`

\- Evitar “colar tokens” em arquivos versionados.

\- Centralizar credenciais no backend (Render) e manter VM só como executor.



---



\## 10) Próximos passos sugeridos (para fechar o projeto “redondo”)

1\) \*\*Host (Chrome)\*\*: script definitivo “captura e envia” (WS URL + Origin + Cookie se houver)

2\) \*\*Render\*\*: endpoint para salvar/atualizar credenciais (admin)

3\) \*\*VM Worker\*\*: sempre buscar credenciais do Render no início do job

4\) \*\*Hardening\*\*:

&nbsp;  - Timeouts padronizados (15s)

&nbsp;  - Logs curtos e acionáveis (mtkn + action + process\_id)

&nbsp;  - Cleanup do `sb\_run\_vm.js` (sem duplicatas)



---



\## 11) Glossário rápido

\- \*\*mtkn\*\*: token/identificador de mensagem/solicitação no WS

\- \*\*process\_id\*\*: id do processo criado/associado no fluxo (necessário para review/execute)

\- \*\*associate\*\*: etapa que vincula ação/veículo e geralmente retorna process\_id

\- \*\*review\*\*: validação/preview do que será executado

\- \*\*execute\*\*: execução efetiva da ação



---



\## 12) Segurança (regras)

\- Nunca commitar tokens/cookies.

\- Em docs e prints, usar placeholders:

&nbsp; - `<TOKEN>`, `<GUID>`, `<COOKIE>`

\- Preferir variáveis de ambiente ou store seguro no backend.



---

Fim.



