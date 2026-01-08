\# Monitor Backend + Worker — Contexto (fonte da verdade)



> \*\*Regra de ouro:\*\* este repositório (monitor-backend-context) é a referência do projeto.  

> Quando houver conflito entre “memória do chat” e docs do repo, \*\*vale o repo\*\*.



\## Estado atual (ATUALIZE A CADA SESSÃO)

\- \*\*Data:\*\* 2026-01-01

\- \*\*Objetivo da sessão:\*\* atualizar documentação + habilitar snapshots da VM no repo de contexto

\- \*\*Status:\*\* OK

\- \*\*Bloqueio atual:\*\* —



\### Versões

\- \*\*monitor-backend (VM):\*\* branch=`(preencher)` sha=`(preencher)`

\- \*\*monitor-backend-context (HOST):\*\* sha=`(preencher)`

\- \*\*Render token status (última validação):\*\* `hasToken=true` `tokenLen=42` `path=/tmp/.session\_token` (HTTP 200)



\### Próximos passos (1–3)

1\) Consolidar este `context.md` no repo (commit/push na HOST)

2\) Rodar VM Snapshot sempre que mudar worker/payload/WS

3\) Manter `RUNBOOK.md` com checklist operacional (se ainda não existir, criar)



---



\## Objetivo

\- \*\*Backend (Render):\*\* recebe requests do app, administra token, mantém fila de jobs.

\- \*\*Worker (VM):\*\* consome jobs e executa ações no Monitor via \*\*WebSocket\*\*.



---



\## Premissas (não-negociáveis)

\- O Monitor (UI) \*\*NÃO exibe\*\* token/cookie/infos críticas para debug/integração.

\- Payload das ações deve ser \*\*idêntico\*\* ao payload da UI (\*\*sem aproximação\*\*).

\- \*\*Não\*\* commitar segredos (token/cookie/admin keys). Em docs, use placeholders.



---



\## Arquitetura (visão rápida)



App/Operação  

→ Backend (Render) \[API + job queue + token store]  

→ Worker (VM) \[poll jobs]  

→ Traffilog Monitor WS (websocket.traffilog.com:8182) \[frames associate/review/execute]



---



\## Repositórios e onde ficam (HOST vs VM)

\- \*\*HOST (Windows):\*\* repo de contexto  

&nbsp; - path: `C:\\Projetos\\monitor-backend-context`

&nbsp; - repo: `Marcusfilho/monitor-backend-context`

\- \*\*VM (Linux):\*\* repo do sistema (backend/worker)  

&nbsp; - path: `~/monitor-backend`

&nbsp; - repo: `Marcusfilho/monitor-backend`



> A ideia é: \*\*doc vive na HOST\*\*, e a \*\*VM publica snapshots\*\* (arquivos novos) no repo de contexto.



---



\## Endpoints e ações (mapa)

\### Auth (api-il)

\- `user\_login` → obtém `session\_token` (usado para acessar o WS)



\### Backend (Render)

\- `POST /api/scheme-builder/start` → cria job

\- `GET  /api/jobs/<id>` → status/result do job

\- `GET  /api/admin/session-token/status` → status do token (protegido por admin key)

\- `POST /api/admin/session-token` → atualizar token (protegido por admin key)



\### WebSocket (Traffilog Monitor)

\- Host típico: `wss://websocket.traffilog.com:8182/<GUID>/<TOKEN>/json?defragment=1`

\- Frames típicos do fluxo:

&nbsp; - `associate\_vehicles\_actions\_opr`

&nbsp; - `get\_vcls\_action\_review\_opr`

&nbsp; - `execute\_action\_opr`



Campos sensíveis (costumam causar 403/timeout):

\- `flow\_id`, `mtkn`, `\_action\_name`, `call\_num`, `action\_source`

\- tipos \*\*string vs number\*\* (muito importante)



---



\## Variáveis de ambiente (inventário)

> \*\*Nunca commitar segredos.\*\* Guardar em `.env` local / Render env vars / override systemd.



\### Backend (Render)

\- `ADMIN\_KEY=...` (para endpoints `/api/admin/\*`)

\- `TRAFFILOG\_LOGIN\_NAME=...`

\- `TRAFFILOG\_PASSWORD=...`

\- `TRAFFILOG\_APP\_GUID=...`

\- `TRAFFILOG\_APP\_VER=1`



\### Worker (VM)

\- `BASE\_URL=https://monitor-backend-...onrender.com`

\- tuning/timeouts (quando aplicável): `WS\_WAIT\_TIMEOUT\_MS=...`



---



\## Onde mexer no código (mapa rápido)

> \*\*Confirmar com grep\*\* quando mover/refatorar.



\- Rotas admin token:

&nbsp; - `src/routes/adminRoutes.ts` (ex.: `/api/admin/session-token/status`)

\- Token store:

&nbsp; - `src/services/sessionTokenStore.ts` (ou equivalente)

\- Fluxo SchemeBuilder / WS:

&nbsp; - `src/services/schemeBuilderService.ts`

\- Worker runner:

&nbsp; - `src/worker/schemeBuilderWorker.ts` (ou equivalente)

\- Ferramentas de teste local:

&nbsp; - `tools/sb\_run\_vm.js`



Greps úteis:

```bash

grep -RIn --exclude-dir=node\_modules --exclude-dir=dist "associate\_vehicles\_actions\_opr" src tools || true

grep -RIn --exclude-dir=node\_modules --exclude-dir=dist "get\_vcls\_action\_review\_opr|execute\_action\_opr" src tools || true

grep -RIn --exclude-dir=node\_modules --exclude-dir=dist "user\_login|session\_token|session-token" src tools || true

```



---



\## Como testar (comandos canônicos)



\### HOST (Windows PowerShell) — Git do contexto

Antes de editar:

```powershell

cd C:\\Projetos\\monitor-backend-context

git pull

git status -sb

```



Depois de editar:

```powershell

cd C:\\Projetos\\monitor-backend-context

git add context.md README.md RUNBOOK.md

git commit -m "docs: update context (YYYY-MM-DD)"

git push

```



\### HOST (Windows PowerShell) — Token (admin)



> No PowerShell, `curl` é alias de `Invoke-WebRequest`. Use `curl.exe`.



```powershell

$BASE = "https://monitor-backend-1pm8.onrender.com"

$ADMIN\_KEY = "<SUA\_CHAVE>".Trim()



curl.exe -sS -H ("x-admin-key: {0}" -f $ADMIN\_KEY) "$BASE/api/admin/session-token/status"

```



(Com debug, só quando der problema)

```powershell

curl.exe -sS -v -H ("x-admin-key: {0}" -f $ADMIN\_KEY) "$BASE/api/admin/session-token/status"

```



\### HOST (Windows PowerShell) — Start job / Job status

```powershell

$BASE = "https://monitor-backend-1pm8.onrender.com"



$body = @{

&nbsp; clientId = 218572

&nbsp; clientName = "TransLima"

&nbsp; vehicleId = 1940478

&nbsp; vehicleSettingId = 5592

&nbsp; comment = "run"

} | ConvertTo-Json



curl.exe -sS -X POST "$BASE/api/scheme-builder/start" -H "Content-Type: application/json" -d $body

curl.exe -sS "$BASE/api/jobs/<id>"

```



\### VM (worker) — build + restart + logs

```bash

cd ~/monitor-backend

git status -sb

git rev-parse --abbrev-ref HEAD

git rev-parse HEAD



npm run build

sudo systemctl restart monitor-schemebuilder-worker

sudo journalctl -u monitor-schemebuilder-worker -n 80 --no-pager -o cat

```



---



\## Ritual de Sync (para abrir qualquer chat “zerado”)



\### HOST SYNC PACK (cola no chat)

```powershell

cd C:\\Projetos\\monitor-backend-context

git status -sb

git rev-parse HEAD

git log -1 --oneline



$BASE = "https://monitor-backend-1pm8.onrender.com"

$ADMIN\_KEY = "<SUA\_CHAVE>".Trim()

curl.exe -sS -H ("x-admin-key: {0}" -f $ADMIN\_KEY) "$BASE/api/admin/session-token/status"

```



\### VM SYNC PACK (cola no chat quando o assunto for worker/WS)

```bash

cd ~/monitor-backend

git status -sb

git rev-parse HEAD

sudo systemctl status monitor-schemebuilder-worker --no-pager -l | head -n 40

sudo journalctl -u monitor-schemebuilder-worker -n 60 --no-pager -o cat

```



---



\## Publicar “realidade da VM” no repo de contexto (snapshots)



\### Objetivo

Evitar editar manualmente o `context.md` para “provar estado da VM”: a VM publica arquivos novos em `sessions/vm/`.



\### Na VM (com repo clonado): rodar

```bash

cd ~/monitor-backend-context

./tools\_publish\_vm\_snapshot.sh

```



Resultado esperado:

\- cria `sessions/vm/YYYY-MM-DD\_HHMMSS\_snapshot.md`

\- dá `git commit` e `git push`



\### Na HOST: puxar

```powershell

cd C:\\Projetos\\monitor-backend-context

git pull

git log -1 --oneline

```



---



\## Captura do WS (Host Chrome) — net-export e sniffer



\### Net-export (chrome://net-export)

\- O WS costuma aparecer como GET `/GUID/TOKEN/json?defragment=1`

\- \*\*Origin\*\* típico: `https://operation.traffilog.com`

\- Pode não aparecer `Cookie` no handshake (auth pode estar no \*\*TOKEN da URL\*\*)

\- Opções importantes:

&nbsp; - \*\*Include cookies and credentials = ON\*\*

&nbsp; - \*\*Strip private information = OFF\*\*



\### Sniffer (Chrome Console)

\- Sniffer “WS amplo”: hook em `WebSocket.prototype.send`

&nbsp; - filtra por chaves (vehicle\_id, action\_id, review/execute/associate etc.)

&nbsp; - decodifica `%...` com `decodeURIComponent` e tenta `JSON.parse`

&nbsp; - loga `ws\_url`, `action.name`, `flow\_id`, `root\_keys/param\_keys`, ids (vehicle/action/process/unit/inner)

\- Fallback: sniffer via `window.fetch` e `XMLHttpRequest` quando a execução não passa pelo WS.



> \*\*Importante:\*\* o objetivo do sniffer é copiar o payload real e bater 1:1 no worker.



---



\## Troubleshooting (sintoma → causa provável → ação)



\### 401 / unauthorized (admin endpoints)

\- Causa: header `x-admin-key` ausente/errado.

\- No PowerShell: usar `curl.exe` (não `curl`).

\- Ação: testar com `curl.exe -v` para verificar se o header foi enviado.



\### 403 (forbidden) no WS

\- Causa: payload divergente (tipos num/string; flow\_id/mtkn; \_action\_name; call\_num; action\_source).

\- Ação: comparar com payload capturado no sniffer (UI real), sem “inventar”.



\### timeout aguardando resposta (WS)

\- Causa: `waitRowByMtkn` falhando / mtkn mismatch / WS fechando.

\- Ação: aumentar log do frame enviado + campos essenciais da resposta; validar onde vem `process\_id`.



\### “Worker parece cacheado / usando dist velho”

\- Causas comuns:

&nbsp; - não rodou `npm run build`

&nbsp; - não reiniciou systemd

&nbsp; - serviço apontando para arquivo/dir antigo

\- Ação: confirmar `git sha`, rebuild e restart; conferir `systemctl cat` e `systemctl show ... FragmentPath/DropInPaths`.



---



\## Regras de segurança (sempre)

\- Nunca commitar tokens/cookies/admin keys.

\- Em docs, usar placeholders: `<TOKEN>`, `<GUID>`, `<COOKIE>`, `<ADMIN\_KEY>`.

\- Se salvar logs/snapshots, manter curtos e, quando possível, com redaction.



---



\## Histórico de sessões (append)

\- \*\*2026-01-01\*\* — Docs + setup snapshot VM | Resultado: token status OK na HOST (curl.exe) + snapshot VM publicado | Bloqueio: —


---


## 2026-01-02 — sb_run_vm.js (VM) — WS autologin + execute OK

Estado atual (OK):
- Autologin via WebSocket funcionando: quando não existe token, faz `user_login` e salva em `/tmp/.session_token` (len ~42).
- Execução destravada e validada: `get_vcls_action_review_opr` retorna `process_id`, e `execute_action_opr` retorna `action_value=0`.
- Portal/Monitor registra corretamente e gera 2 processos por execução (igual ao uso manual):
  1) Assign Setting
  2) Run Scheme builder
- Comentário é propagado para ambos os processos.

Correções aplicadas:
- Removido/evitado `associate_vehicles_actions_opr` extra que retornava `403 action forbidden`.
- Fluxo de review/execute passou a usar `get_vcls_action_review_opr` direto (sem depender de associate para gerar process_id).
- Tag de rastreio no comentário:
  - `#rid=<run_id>` gerado no início da execução
  - `#pid=<process_id>` anexado após obter o process_id
  - Exemplo: `... #rid=1767373667936_b0eaa3 #pid=8891183`

Comando de teste (VM):
WS_DEBUG=1 node tools/sb_run_vm.js 218572 "TransLima" 1940478 5592 "manual test (associate+execute)"

Resultado esperado no log:
- `[sb] process_id = <número>`
- `execute_action_opr enviado.`
- `action_value=0`

Observação:
- Duplicidade aparente no histórico ocorre quando a execução é disparada mais de uma vez; agora é identificável via `#rid/#pid`.


## 2026-01-04 — Monitor Backend (VM Tunel) — G-Sensor / GS2 (403 “action forbidden”)

### Regra permanente (arquitetura de autenticação)
- **Sempre gerar/renovar `session_token` via HTTP `user_login`** (API Traffilog) antes de qualquer fluxo (SB, G-Sensor etc.).
- Usar esse token em todas as requisições/WS. Evitar depender de captura manual de token/WS URL.
- Não armazenar senha em arquivo: usar credenciais via env (`WS_LOGIN_NAME` / `WS_PASSWORD`).
- Emitir aviso claro quando DNS/rota/VPN impedir acesso ao WebSocket.
- Token cache em arquivo (ex.: `/tmp/.session_token`) pode ser apagado para forçar renovação.

### Sintoma atual
- Fluxo **SchemeBuilder (SB)** executa normalmente (exemplo):
  - `get_client_vehicles_opr` → `vcls_check_opr` → `associate_vehicles_actions_opr` → `review_process_attributes` → `get_vcls_action_review_opr` → `execute_action_opr`
  - Retornos com envelope padrão: `response.properties.action_value = "0"`.

- Fluxo **G-Sensor (GS2)** não “entra” no Monitor e falha no WS:
  - A maioria das actions do GS2 retorna **raw** `{ action_value: '403', error_description: 'action forbidden' }`.
  - O erro fatal ocorre em `review_process_attributes` do GS2 (403).

### Evidências (log típico)
- No mesmo run:
  - `[sb] << action_value msg: { response: { properties: { action_name: 'get_client_vehicles_opr', action_value: '0', data:[...] }}}`
  - Mais tarde, dentro do GS2:
    - `get_client_vehicles_opr` chamado novamente → retorna **403** (raw).
    - `get_custom_command` / `associate_vehicles_actions_opr` / `review_process_attributes` → **403**.

### Tentativas/patches já feitos (resumo)
- **GS_ACTION_ID**: várias tentativas; brute-force + auto-discover (1..250) resultou em **403 para todos** ao chamar `associate_vehicles_actions_opr` no GS2.
- `add_remove_custom_command` / `get_custom_command` / `associate_vehicles_actions_opr`: tentativa de ignorar 403 para “seguir fluxo”; mesmo assim quebra em `review_process_attributes` 403.
- Tentativa de enriquecer payload com `unit_key/inner_id` (UI costuma enviar) falhou porque o GS2 não consegue buscar `get_client_vehicles_opr` (403) para extrair contexto.
- Observação: `GS_DISCOVER` gerou flood e apareceu `MaxListenersExceededWarning` (loop de chamadas adicionando listeners).

### Hipótese técnica mais provável
- O **payload/contexto do GS2 não replica o que a UI envia** (campos adicionais/ordem/flags), levando o backend a negar as actions com 403.
- Campos possivelmente exigidos no GS (observado em sniffers anteriores): `unit_key`, `inner_id`, `oid` e/ou outros metadados do comando/veículo.
- `net-export` do Chrome não expõe payload do WSS (TLS), então não serve para reconstruir o frame real do GS.

### Próximo passo (direção correta)
1) Capturar o **frame real** do envio GS no portal (sniffer `WebSocket.prototype.send` já usado no projeto: SB2-SEND), filtrando por:
   - `action_name`, `action_id`, `unit_key`, `inner_id`, `oid`, `review`, `execute`, `associate`, `vehicle_id`.
2) Replicar no worker **exatamente** o payload da UI (mesmos campos e valores).
3) Alternativa: cachear `get_client_vehicles_opr` do SB e reutilizar no GS2 para obter `unit_key/inner_id` (sem refetch no GS2), caso o backend permita.

### Arquivos e ambiente
- VM: `questar@Tunel`, Node.js v20.19.6
- Arquivo principal de teste: `tools/sb_run_vm.js`
- Teste padrão:
  - `rm -f /tmp/.session_token`
  - `WS_DEBUG=1 GS_ENABLE=1 GS_DELAY_MS=1500 GS_ACTION_ID=5 node tools/sb_run_vm.js 218572 "TransLima" 1940478 5592 "SB+GS test"`




## Marco concluído — G-Sensor como "Run command" (GS2 CHROME_FLOW) ✅

### Problema
O envio de **Run command / G-Sensor** no portal não carrega `vehicle_id` no payload do comando.
O vínculo com o veículo vem do "select" da UI: `vcls_check_opr` com `is_checked=1`.

### Solução
Implementado `GS2 CHROME_FLOW` em `tools/sb_run_vm.js` para replicar a sequência real do Chrome:

1) `vcls_check_opr` (select vehicle)  
   `{ client_id, vehicle_id, client_name, is_checked:"1" }`

2) `associate_vehicles_actions_opr` (call_num=0)  
   `{ client_id, client_name, action_source:"0", action_id:"5", call_num:"0" }`

3) `get_custom_command`  
   `{ client_id }`

4) (opcional) `add_remove_custom_command` (quando "+add manual command")  
   `{ client_id, acknowledge_needed:"1", command_syntax:"(...)", action_value:"0" }`

5) `associate_vehicles_actions_opr` (call_num=1, keep_priority)  
   `{ client_id, client_name, keep_priority:true, action_source:"0", action_id:"5", call_num:"1" }`

6) `review_process_attributes` + `get_vcls_action_review_opr` -> extrai `process_id`  
   - `review_process_attributes`: `{ client_id }`  
   - `get_vcls_action_review_opr`: `{ client_id, client_name, action_source:"0" }`

7) `execute_action_opr` (payload mínimo do portal)  
   `{ tag:"loading_screen", client_id, action_source:"0", process_id, comment, toggle_check:"0" }`

### Observação importante (ordem SB/CAN/GS)
`execute_action_opr` do SB apenas **enfileira** o processo; o SB continua rodando em background.
Por isso, o GS pode concluir e aparecer antes no histórico.
No worker final, o pipeline será: **SB -> aguardar concluir -> validar CAN -> GS** (etapas separadas).

### Variáveis de ambiente úteis
- `GS_ENABLE=1`
- `GS_ACTION_ID=5`
- `GS_DELAY_MS=1500`
- `GS_COMMAND_SYNTAX='(...)'` (para "+add manual command")
- `GS_COMMENT_SUFFIX=' [GS]'` (dedup no código para evitar `[GS][GS]`)

### Teste (VM)
```bash
rm -f /tmp/.session_token
GS_ENABLE=1 GS_ACTION_ID=5 GS_DELAY_MS=1500 \
GS_COMMENT_SUFFIX=" [GS]" \
GS_COMMAND_SYNTAX='(o2w,44,C6140400000000000000040000000000000004000000)' \
WS_DEBUG=1 \
node tools/sb_run_vm.js 218572 "TransLima" 1940478 5592 "SB+GS test"



## Vehicle Monitor Snapshot — vm_snapshot_ws_v4.js (v4.7.2)

Objetivo: criar um snapshot “espelho” do Vehicle Monitor com:
- Header (online + dados reais)
- Module State (inclui CAN0/CAN1/J1708/KEYPAD*)
- Parameters (garantindo valores — via refresh/push)

Pontos-chave:
- Token fresh via user_login (HTTP) e WS URL fresh
- vehicle_subscribe é fire-and-forget (sem mtkn)
- Parameters: não encerra enquanto não houver valores (refresh_values > 0 ou count_with_value > 0)
- Captura valores via action "refresh" / data_source contendo "UNIT_PARAM"
- Debug de WS em /tmp/vm_ws_debug_<VID>_<ts>.json (amostra maior via WS_DEBUG_SAMPLE_LEN)

Como rodar (VM):
- Ajustar envs e executar:
  - node tools/vm_snapshot_ws_v4.js <VEHICLE_ID> > /tmp/vm_snapshot_<VID>_v4.json

Critério de sucesso do marco:
- parameters_tab.count_with_value > 0 e/ou parameters_tab.refresh_values > 0
- debug.params_refresh.reason == has_refresh_values (ou has_row_values)

Artefato do marco:
- ZIP em snapshots/ contendo tool + snapshot + ws_debug + evidências git.



\# Monitor Backend + Worker — Contexto (fonte da verdade)



> \*\*Regra de ouro:\*\* este repositório (monitor-backend-context) é a referência do projeto.  

> Quando houver conflito entre “memória do chat” e docs do repo, \*\*vale o repo\*\*.



\## Estado atual (ATUALIZE A CADA SESSÃO)

\- \*\*Data:\*\* 2026-01-01

\- \*\*Objetivo da sessão:\*\* atualizar documentação + habilitar snapshots da VM no repo de contexto

\- \*\*Status:\*\* OK

\- \*\*Bloqueio atual:\*\* —



\### Versões

\- \*\*monitor-backend (VM):\*\* branch=`(preencher)` sha=`(preencher)`

\- \*\*monitor-backend-context (HOST):\*\* sha=`(preencher)`

\- \*\*Render token status (última validação):\*\* `hasToken=true` `tokenLen=42` `path=/tmp/.session\_token` (HTTP 200)



\### Próximos passos (1–3)

1\) Consolidar este `context.md` no repo (commit/push na HOST)

2\) Rodar VM Snapshot sempre que mudar worker/payload/WS

3\) Manter `RUNBOOK.md` com checklist operacional (se ainda não existir, criar)



---



\## Objetivo

\- \*\*Backend (Render):\*\* recebe requests do app, administra token, mantém fila de jobs.

\- \*\*Worker (VM):\*\* consome jobs e executa ações no Monitor via \*\*WebSocket\*\*.



---



\## Premissas (não-negociáveis)

\- O Monitor (UI) \*\*NÃO exibe\*\* token/cookie/infos críticas para debug/integração.

\- Payload das ações deve ser \*\*idêntico\*\* ao payload da UI (\*\*sem aproximação\*\*).

\- \*\*Não\*\* commitar segredos (token/cookie/admin keys). Em docs, use placeholders.
\- O worker vai operar em \*\*3 atuações\*\*: \*\*Instalação\*\*, \*\*Manutenção\*\* (com troca / sem troca) e \*\*Desinstalação\*\*.
\- O Monitor (SB + CAN + GS) roda \*\*somente\*\* quando houver \*\*novo equipamento instalado\*\*: Instalação e Manutenção com troca.
\- \*\*Regra disciplinar\*\*: todo serial que vai a campo deve estar \*\*pré-registrado/testado\*\* no sistema. Se o serial não existir no HTML5/estoque, \*\*travar\*\* o processo com erro claro (ex.: SERIAL_NOT_REGISTERED) para o técnico acionar o supervisor.

---



\## Arquitetura (visão rápida)



App/Operação  

→ Backend (Render) \[API + job queue + token store]  

→ Worker (VM) \[poll jobs]  

→ Traffilog Monitor WS (websocket.traffilog.com:8182) \[frames associate/review/execute]



---



\## Repositórios e onde ficam (HOST vs VM)

\- \*\*HOST (Windows):\*\* repo de contexto  

&nbsp; - path: `C:\\Projetos\\monitor-backend-context`

&nbsp; - repo: `Marcusfilho/monitor-backend-context`

\- \*\*VM (Linux):\*\* repo do sistema (backend/worker)  

&nbsp; - path: `~/monitor-backend`

&nbsp; - repo: `Marcusfilho/monitor-backend`



> A ideia é: \*\*doc vive na HOST\*\*, e a \*\*VM publica snapshots\*\* (arquivos novos) no repo de contexto.



---




\## Projeto Instalador (V1) — Fluxo ponta-a-ponta (App → Backend → Worker → HTML5/Monitor)

\### Conceitos (IDs e tokens)
\- \*\*installation_id\*\*: UUID criado no \*\*Backend\*\* no \*\*primeiro submit\*\* do App (uma instalação/manutenção/desinstalação). É o ID de correlação ponta-a-ponta.

\- \*\*installation_token\*\*: token curto escopado \*\*apenas\*\* àquela instalação (permite o App ler status, pedir snapshot e aprovar CAN sem “login pesado”). TTL sugerido: 24h (ajustável).

\- \*\*installer_token\*\*: token do técnico (identificação leve). V1: técnico informa \*\*CPF\*\* 1x no aparelho → Backend emite token e o App guarda localmente. \*\*TTL V1: 30 dias\*\*. Backend deve armazenar CPF em formato seguro (hash + salt) e, opcionalmente, final-4 para exibição.

\### Tipos de atuação (operation_type)
\- \*\*INSTALL\*\*: instalação de novo equipamento em nova placa.

\- \*\*MAINT_SWAP\*\*: manutenção com troca (novo equipamento em placa já existente).

\- \*\*MAINT_NO_SWAP\*\*: manutenção sem troca (somente registro; sem HTML5/Monitor).

\- \*\*UNINSTALL\*\*: desinstalação (remover equipamento do veículo).

\*\*requires_monitor\*\* (derivado):

\- INSTALL → true

\- MAINT_SWAP → true

\- MAINT_NO_SWAP → false

\- UNINSTALL → false

\### Pipeline por tipo (V1)

\*\*INSTALL (com Monitor)\*\*
1) Backend cria installation_id e grava estado \*\*CREATED\*\*.

2) Worker (HTML5):
   \- valida que \*\*serial\*\* existe (pré-registrado/testado). Se não existir → \*\*SERIAL_NOT_REGISTERED\*\* (hard stop).
   \- resolve \*\*vehicle_id\*\* via lookup por serial.
   \- atualiza cadastro (placa, modelo, installation_date, técnico, etc.).

3) Worker (Monitor):
   \- envia \*\*Scheme Builder\*\*.
   \- aguarda término da atualização + reboot (ver regras de espera abaixo).
   \- inicia snapshots CAN e envia dados ao Backend para exibição no App.

4) Técnico valida CAN no App e confirma:
   \- aprova CAN → Backend muda para \*\*CAN_APPROVED\*\* e dispara GS.
   \- aprova sem validar (ex.: veículo novo sem engenharia) → \*\*CAN_APPROVED_OVERRIDE\*\*.

5) Worker envia calibração \*\*G-Sensor\*\* usando orientação informada no início.

6) Backend marca \*\*COMPLETED\*\* e registra evidências (logs + snapshot final + resultado GS).

\*\*MAINT_SWAP (com Monitor)\*\*
1) Mesmo fluxo do INSTALL, com passos HTML5 adicionais:
   \- descadastrar serial atual do vehicle_id (desinstalação lógica).
   \- cadastrar serial novo no mesmo vehicle_id (serial + nova data + técnico).
   \- \*\*Regra disciplinar\*\*: serial novo precisa existir (pré-registrado/testado); caso contrário, travar.

2) Depois: Monitor (SB → wait → CAN → GS) igual ao INSTALL.

\*\*MAINT_NO_SWAP (sem Monitor / sem HTML5)\*\*
\- Backend registra a atuação (tabela/lista) e marca \*\*COMPLETED\*\*.

\*\*UNINSTALL (sem Monitor)\*\*
1) Worker resolve vehicle_id (lookup por serial) e faz descadastro do serial.

2) Backend registra a atuação e marca \*\*COMPLETED\*\*.

\### Regras de espera (SB → reboot → CAN)
\- Após enviar SB, o worker entra em \*\*SB_RUNNING\*\* e deve reportar \*\*configuration_status\*\* + \*\*configuration_progress\*\* periodicamente ao Backend/App (ex.: a cada 10–20s).

\- O worker \*\*não inicia snapshots CAN\*\* antes de:
  1) progress/status indicar conclusão (ex.: progress=100%/completed) \*\*e\*\*
  2) \*\*gprs_last\*\* indicar retorno “agora/recente” (sinal de reboot + online).

\- Snapshots CAN:
  \- “bateria” inicial: até 10 forceRefresh, intervalo 10s.
  \- se capturar dado válido (ver critérios abaixo), encerra a bateria e envia ao Backend.
  \- se falhar, o App permite o técnico pedir novas baterias quantas vezes quiser (sem reexecutar SB/GS).

\### CAN no App (V1)
\- Header: configuration_status/progress, manufacturer/model, ignition, gprs_last, driver_code.

\- Module State: exibir quais barramentos estão OK (CAN0/CAN1/J1708) e qual identificador está OK (DALLAS/RAMZOR).

\- Parameters: backend armazena todos que casem “J1939” e “sys param”; App exibe apenas os campos-chave (odômetro, combustível, RPM, temperatura, etc.) com fallbacks.

\- Ações:
  \- \*\*Atualizar snapshot\*\* (repetir bateria de snapshots).
  \- \*\*Aprovar CAN\*\* (CAN_APPROVED).
  \- \*\*Aprovar sem validar\*\* (CAN_APPROVED_OVERRIDE, com motivo opcional).

\### Idempotência (cliques duplicados)
\- A chave de correlação é o installation_id; cada transição é validada (não pode “pular” etapas).

\- Repetir ações deve ser seguro:
  \- pedir snapshot CAN é sempre permitido após SB_DONE.
  \- SB/GS só rodam uma vez por instalação, salvo “force” controlado (admin).

\### Erros padronizados (V1)
\- SERIAL_NOT_REGISTERED (serial não existe no sistema / não testado)

\- SB_TIMEOUT / SB_STUCK_PROGRESS

\- WS_NETWORK (VPN/DNS/rota)

\- CAN_NO_SIGNAL (após bateria de snapshots, sem valores)

\- HTML5_ERROR (falha de cadastro/descadastro)



\## Endpoints e ações (mapa)

\### Auth (api-il)

\- `user\_login` → obtém `session\_token` (usado para acessar o WS)



\### Backend (Render)

\- `POST /api/scheme-builder/start` → cria job

\- `GET  /api/jobs/<id>` → status/result do job

\- `GET  /api/admin/session-token/status` → status do token (protegido por admin key)

\- `POST /api/admin/session-token` → atualizar token (protegido por admin key)



\### WebSocket (Traffilog Monitor)

\- Host típico: `wss://websocket.traffilog.com:8182/<GUID>/<TOKEN>/json?defragment=1`

\- Frames típicos do fluxo:

&nbsp; - `associate\_vehicles\_actions\_opr`

&nbsp; - `get\_vcls\_action\_review\_opr`

&nbsp; - `execute\_action\_opr`



Campos sensíveis (costumam causar 403/timeout):

\- `flow\_id`, `mtkn`, `\_action\_name`, `call\_num`, `action\_source`

\- tipos \*\*string vs number\*\* (muito importante)



---



\## Variáveis de ambiente (inventário)

> \*\*Nunca commitar segredos.\*\* Guardar em `.env` local / Render env vars / override systemd.



\### Backend (Render)

\- `ADMIN\_KEY=...` (para endpoints `/api/admin/\*`)

\- `TRAFFILOG\_LOGIN\_NAME=...`

\- `TRAFFILOG\_PASSWORD=...`

\- `TRAFFILOG\_APP\_GUID=...`

\- `TRAFFILOG\_APP\_VER=1`



\### Worker (VM)

\- `BASE\_URL=https://monitor-backend-...onrender.com`

\- tuning/timeouts (quando aplicável): `WS\_WAIT\_TIMEOUT\_MS=...`



---



\## Onde mexer no código (mapa rápido)

> \*\*Confirmar com grep\*\* quando mover/refatorar.



\- Rotas admin token:

&nbsp; - `src/routes/adminRoutes.ts` (ex.: `/api/admin/session-token/status`)

\- Token store:

&nbsp; - `src/services/sessionTokenStore.ts` (ou equivalente)

\- Fluxo SchemeBuilder / WS:

&nbsp; - `src/services/schemeBuilderService.ts`

\- Worker runner:

&nbsp; - `src/worker/schemeBuilderWorker.ts` (ou equivalente)

\- Ferramentas de teste local:

&nbsp; - `tools/sb\_run\_vm.js`



Greps úteis:

```bash

grep -RIn --exclude-dir=node\_modules --exclude-dir=dist "associate\_vehicles\_actions\_opr" src tools || true

grep -RIn --exclude-dir=node\_modules --exclude-dir=dist "get\_vcls\_action\_review\_opr|execute\_action\_opr" src tools || true

grep -RIn --exclude-dir=node\_modules --exclude-dir=dist "user\_login|session\_token|session-token" src tools || true

```



---



\## Como testar (comandos canônicos)



\### HOST (Windows PowerShell) — Git do contexto

Antes de editar:

```powershell

cd C:\\Projetos\\monitor-backend-context

git pull

git status -sb

```



Depois de editar:

```powershell

cd C:\\Projetos\\monitor-backend-context

git add context.md README.md RUNBOOK.md

git commit -m "docs: update context (YYYY-MM-DD)"

git push

```



\### HOST (Windows PowerShell) — Token (admin)



> No PowerShell, `curl` é alias de `Invoke-WebRequest`. Use `curl.exe`.



```powershell

$BASE = "https://monitor-backend-1pm8.onrender.com"

$ADMIN\_KEY = "<SUA\_CHAVE>".Trim()



curl.exe -sS -H ("x-admin-key: {0}" -f $ADMIN\_KEY) "$BASE/api/admin/session-token/status"

```



(Com debug, só quando der problema)

```powershell

curl.exe -sS -v -H ("x-admin-key: {0}" -f $ADMIN\_KEY) "$BASE/api/admin/session-token/status"

```



\### HOST (Windows PowerShell) — Start job / Job status

```powershell

$BASE = "https://monitor-backend-1pm8.onrender.com"



$body = @{

&nbsp; clientId = 218572

&nbsp; clientName = "TransLima"

&nbsp; vehicleId = 1940478

&nbsp; vehicleSettingId = 5592

&nbsp; comment = "run"

} | ConvertTo-Json



curl.exe -sS -X POST "$BASE/api/scheme-builder/start" -H "Content-Type: application/json" -d $body

curl.exe -sS "$BASE/api/jobs/<id>"

```



\### VM (worker) — build + restart + logs

```bash

cd ~/monitor-backend

git status -sb

git rev-parse --abbrev-ref HEAD

git rev-parse HEAD



npm run build

sudo systemctl restart monitor-schemebuilder-worker

sudo journalctl -u monitor-schemebuilder-worker -n 80 --no-pager -o cat

```



---



\## Ritual de Sync (para abrir qualquer chat “zerado”)



\### HOST SYNC PACK (cola no chat)

```powershell

cd C:\\Projetos\\monitor-backend-context

git status -sb

git rev-parse HEAD

git log -1 --oneline



$BASE = "https://monitor-backend-1pm8.onrender.com"

$ADMIN\_KEY = "<SUA\_CHAVE>".Trim()

curl.exe -sS -H ("x-admin-key: {0}" -f $ADMIN\_KEY) "$BASE/api/admin/session-token/status"

```



\### VM SYNC PACK (cola no chat quando o assunto for worker/WS)

```bash

cd ~/monitor-backend

git status -sb

git rev-parse HEAD

sudo systemctl status monitor-schemebuilder-worker --no-pager -l | head -n 40

sudo journalctl -u monitor-schemebuilder-worker -n 60 --no-pager -o cat

```



---



\## Publicar “realidade da VM” no repo de contexto (snapshots)



\### Objetivo

Evitar editar manualmente o `context.md` para “provar estado da VM”: a VM publica arquivos novos em `sessions/vm/`.



\### Na VM (com repo clonado): rodar

```bash

cd ~/monitor-backend-context

./tools\_publish\_vm\_snapshot.sh

```



Resultado esperado:

\- cria `sessions/vm/YYYY-MM-DD\_HHMMSS\_snapshot.md`

\- dá `git commit` e `git push`



\### Na HOST: puxar

```powershell

cd C:\\Projetos\\monitor-backend-context

git pull

git log -1 --oneline

```



---



\## Captura do WS (Host Chrome) — net-export e sniffer



\### Net-export (chrome://net-export)

\- O WS costuma aparecer como GET `/GUID/TOKEN/json?defragment=1`

\- \*\*Origin\*\* típico: `https://operation.traffilog.com`

\- Pode não aparecer `Cookie` no handshake (auth pode estar no \*\*TOKEN da URL\*\*)

\- Opções importantes:

&nbsp; - \*\*Include cookies and credentials = ON\*\*

&nbsp; - \*\*Strip private information = OFF\*\*



\### Sniffer (Chrome Console)

\- Sniffer “WS amplo”: hook em `WebSocket.prototype.send`

&nbsp; - filtra por chaves (vehicle\_id, action\_id, review/execute/associate etc.)

&nbsp; - decodifica `%...` com `decodeURIComponent` e tenta `JSON.parse`

&nbsp; - loga `ws\_url`, `action.name`, `flow\_id`, `root\_keys/param\_keys`, ids (vehicle/action/process/unit/inner)

\- Fallback: sniffer via `window.fetch` e `XMLHttpRequest` quando a execução não passa pelo WS.



> \*\*Importante:\*\* o objetivo do sniffer é copiar o payload real e bater 1:1 no worker.



---



\## Troubleshooting (sintoma → causa provável → ação)



\### 401 / unauthorized (admin endpoints)

\- Causa: header `x-admin-key` ausente/errado.

\- No PowerShell: usar `curl.exe` (não `curl`).

\- Ação: testar com `curl.exe -v` para verificar se o header foi enviado.



\### 403 (forbidden) no WS

\- Causa: payload divergente (tipos num/string; flow\_id/mtkn; \_action\_name; call\_num; action\_source).

\- Ação: comparar com payload capturado no sniffer (UI real), sem “inventar”.



\### timeout aguardando resposta (WS)

\- Causa: `waitRowByMtkn` falhando / mtkn mismatch / WS fechando.

\- Ação: aumentar log do frame enviado + campos essenciais da resposta; validar onde vem `process\_id`.



\### “Worker parece cacheado / usando dist velho”

\- Causas comuns:

&nbsp; - não rodou `npm run build`

&nbsp; - não reiniciou systemd

&nbsp; - serviço apontando para arquivo/dir antigo

\- Ação: confirmar `git sha`, rebuild e restart; conferir `systemctl cat` e `systemctl show ... FragmentPath/DropInPaths`.



---



\## Regras de segurança (sempre)

\- Nunca commitar tokens/cookies/admin keys.

\- Em docs, usar placeholders: `<TOKEN>`, `<GUID>`, `<COOKIE>`, `<ADMIN\_KEY>`.

\- Se salvar logs/snapshots, manter curtos e, quando possível, com redaction.



---



\## Histórico de sessões (append)

\- \*\*2026-01-01\*\* — Docs + setup snapshot VM | Resultado: token status OK na HOST (curl.exe) + snapshot VM publicado | Bloqueio: —


---


## 2026-01-02 — sb_run_vm.js (VM) — WS autologin + execute OK

Estado atual (OK):
- Autologin via WebSocket funcionando: quando não existe token, faz `user_login` e salva em `/tmp/.session_token` (len ~42).
- Execução destravada e validada: `get_vcls_action_review_opr` retorna `process_id`, e `execute_action_opr` retorna `action_value=0`.
- Portal/Monitor registra corretamente e gera 2 processos por execução (igual ao uso manual):
  1) Assign Setting
  2) Run Scheme builder
- Comentário é propagado para ambos os processos.

Correções aplicadas:
- Removido/evitado `associate_vehicles_actions_opr` extra que retornava `403 action forbidden`.
- Fluxo de review/execute passou a usar `get_vcls_action_review_opr` direto (sem depender de associate para gerar process_id).
- Tag de rastreio no comentário:
  - `#rid=<run_id>` gerado no início da execução
  - `#pid=<process_id>` anexado após obter o process_id
  - Exemplo: `... #rid=1767373667936_b0eaa3 #pid=8891183`

Comando de teste (VM):
WS_DEBUG=1 node tools/sb_run_vm.js 218572 "TransLima" 1940478 5592 "manual test (associate+execute)"

Resultado esperado no log:
- `[sb] process_id = <número>`
- `execute_action_opr enviado.`
- `action_value=0`

Observação:
- Duplicidade aparente no histórico ocorre quando a execução é disparada mais de uma vez; agora é identificável via `#rid/#pid`.


## 2026-01-04 — Monitor Backend (VM Tunel) — G-Sensor / GS2 (403 “action forbidden”)

### Regra permanente (arquitetura de autenticação)
- **Sempre gerar/renovar `session_token` via HTTP `user_login`** (API Traffilog) antes de qualquer fluxo (SB, G-Sensor etc.).
- Usar esse token em todas as requisições/WS. Evitar depender de captura manual de token/WS URL.
- Não armazenar senha em arquivo: usar credenciais via env (`WS_LOGIN_NAME` / `WS_PASSWORD`).
- Emitir aviso claro quando DNS/rota/VPN impedir acesso ao WebSocket.
- Token cache em arquivo (ex.: `/tmp/.session_token`) pode ser apagado para forçar renovação.

### Sintoma atual
- Fluxo **SchemeBuilder (SB)** executa normalmente (exemplo):
  - `get_client_vehicles_opr` → `vcls_check_opr` → `associate_vehicles_actions_opr` → `review_process_attributes` → `get_vcls_action_review_opr` → `execute_action_opr`
  - Retornos com envelope padrão: `response.properties.action_value = "0"`.

- Fluxo **G-Sensor (GS2)** não “entra” no Monitor e falha no WS:
  - A maioria das actions do GS2 retorna **raw** `{ action_value: '403', error_description: 'action forbidden' }`.
  - O erro fatal ocorre em `review_process_attributes` do GS2 (403).

### Evidências (log típico)
- No mesmo run:
  - `[sb] << action_value msg: { response: { properties: { action_name: 'get_client_vehicles_opr', action_value: '0', data:[...] }}}`
  - Mais tarde, dentro do GS2:
    - `get_client_vehicles_opr` chamado novamente → retorna **403** (raw).
    - `get_custom_command` / `associate_vehicles_actions_opr` / `review_process_attributes` → **403**.

### Tentativas/patches já feitos (resumo)
- **GS_ACTION_ID**: várias tentativas; brute-force + auto-discover (1..250) resultou em **403 para todos** ao chamar `associate_vehicles_actions_opr` no GS2.
- `add_remove_custom_command` / `get_custom_command` / `associate_vehicles_actions_opr`: tentativa de ignorar 403 para “seguir fluxo”; mesmo assim quebra em `review_process_attributes` 403.
- Tentativa de enriquecer payload com `unit_key/inner_id` (UI costuma enviar) falhou porque o GS2 não consegue buscar `get_client_vehicles_opr` (403) para extrair contexto.
- Observação: `GS_DISCOVER` gerou flood e apareceu `MaxListenersExceededWarning` (loop de chamadas adicionando listeners).

### Hipótese técnica mais provável
- O **payload/contexto do GS2 não replica o que a UI envia** (campos adicionais/ordem/flags), levando o backend a negar as actions com 403.
- Campos possivelmente exigidos no GS (observado em sniffers anteriores): `unit_key`, `inner_id`, `oid` e/ou outros metadados do comando/veículo.
- `net-export` do Chrome não expõe payload do WSS (TLS), então não serve para reconstruir o frame real do GS.

### Próximo passo (direção correta)
1) Capturar o **frame real** do envio GS no portal (sniffer `WebSocket.prototype.send` já usado no projeto: SB2-SEND), filtrando por:
   - `action_name`, `action_id`, `unit_key`, `inner_id`, `oid`, `review`, `execute`, `associate`, `vehicle_id`.
2) Replicar no worker **exatamente** o payload da UI (mesmos campos e valores).
3) Alternativa: cachear `get_client_vehicles_opr` do SB e reutilizar no GS2 para obter `unit_key/inner_id` (sem refetch no GS2), caso o backend permita.

### Arquivos e ambiente
- VM: `questar@Tunel`, Node.js v20.19.6
- Arquivo principal de teste: `tools/sb_run_vm.js`
- Teste padrão:
  - `rm -f /tmp/.session_token`
  - `WS_DEBUG=1 GS_ENABLE=1 GS_DELAY_MS=1500 GS_ACTION_ID=5 node tools/sb_run_vm.js 218572 "TransLima" 1940478 5592 "SB+GS test"`




## Marco concluído — G-Sensor como "Run command" (GS2 CHROME_FLOW) ✅

### Problema
O envio de **Run command / G-Sensor** no portal não carrega `vehicle_id` no payload do comando.
O vínculo com o veículo vem do "select" da UI: `vcls_check_opr` com `is_checked=1`.

### Solução
Implementado `GS2 CHROME_FLOW` em `tools/sb_run_vm.js` para replicar a sequência real do Chrome:

1) `vcls_check_opr` (select vehicle)  
   `{ client_id, vehicle_id, client_name, is_checked:"1" }`

2) `associate_vehicles_actions_opr` (call_num=0)  
   `{ client_id, client_name, action_source:"0", action_id:"5", call_num:"0" }`

3) `get_custom_command`  
   `{ client_id }`

4) (opcional) `add_remove_custom_command` (quando "+add manual command")  
   `{ client_id, acknowledge_needed:"1", command_syntax:"(...)", action_value:"0" }`

5) `associate_vehicles_actions_opr` (call_num=1, keep_priority)  
   `{ client_id, client_name, keep_priority:true, action_source:"0", action_id:"5", call_num:"1" }`

6) `review_process_attributes` + `get_vcls_action_review_opr` -> extrai `process_id`  
   - `review_process_attributes`: `{ client_id }`  
   - `get_vcls_action_review_opr`: `{ client_id, client_name, action_source:"0" }`

7) `execute_action_opr` (payload mínimo do portal)  
   `{ tag:"loading_screen", client_id, action_source:"0", process_id, comment, toggle_check:"0" }`

### Observação importante (ordem SB/CAN/GS)
`execute_action_opr` do SB apenas **enfileira** o processo; o SB continua rodando em background.
Por isso, o GS pode concluir e aparecer antes no histórico.
No worker final, o pipeline será: **SB -> aguardar concluir -> validar CAN -> GS** (etapas separadas).

### Variáveis de ambiente úteis
- `GS_ENABLE=1`
- `GS_ACTION_ID=5`
- `GS_DELAY_MS=1500`
- `GS_COMMAND_SYNTAX='(...)'` (para "+add manual command")
- `GS_COMMENT_SUFFIX=' [GS]'` (dedup no código para evitar `[GS][GS]`)

### Teste (VM)
```bash
rm -f /tmp/.session_token
GS_ENABLE=1 GS_ACTION_ID=5 GS_DELAY_MS=1500 \
GS_COMMENT_SUFFIX=" [GS]" \
GS_COMMAND_SYNTAX='(o2w,44,C6140400000000000000040000000000000004000000)' \
WS_DEBUG=1 \
node tools/sb_run_vm.js 218572 "TransLima" 1940478 5592 "SB+GS test"



## Vehicle Monitor Snapshot — vm_snapshot_ws_v4.js (v4.7.2)

Objetivo: criar um snapshot “espelho” do Vehicle Monitor com:
- Header (online + dados reais)
- Module State (inclui CAN0/CAN1/J1708/KEYPAD*)
- Parameters (garantindo valores — via refresh/push)

Pontos-chave:
- Token fresh via user_login (HTTP) e WS URL fresh
- vehicle_subscribe é fire-and-forget (sem mtkn)
- Parameters: não encerra enquanto não houver valores (refresh_values > 0 ou count_with_value > 0)
- Captura valores via action "refresh" / data_source contendo "UNIT_PARAM"
- Debug de WS em /tmp/vm_ws_debug_<VID>_<ts>.json (amostra maior via WS_DEBUG_SAMPLE_LEN)

Como rodar (VM):
- Ajustar envs e executar:
  - node tools/vm_snapshot_ws_v4.js <VEHICLE_ID> > /tmp/vm_snapshot_<VID>_v4.json

Critério de sucesso do marco:
- parameters_tab.count_with_value > 0 e/ou parameters_tab.refresh_values > 0
- debug.params_refresh.reason == has_refresh_values (ou has_row_values)

Artefato do marco:
- ZIP em snapshots/ contendo tool + snapshot + ws_debug + evidências git.


\## Catálogos DE/PARA (V1) — Clientes, Scheme Builder e Modelos (fonte de verdade do App)

\### Motivação
\- O job do Monitor depende de \*\*vehicle_setting_id (scheme)\*\*, que varia por cliente e, em alguns casos, pode haver \*\*mais de um scheme\*\* por cliente.

\- O cadastro/atualização no HTML5 depende de \*\*client_id\*\* e dos IDs (ou valores normalizados) de \*\*manufacturer/model\*\*.

\- Para manter o App simples (técnico não decide “coisa técnica”), o Backend resolve tudo via \*\*catálogos DE/PARA\*\*.

\### Onde guardar (V1)
\- Manter um arquivo JSON versionado no Backend (repo) como \*\*fonte de verdade\*\*:
  \- `config/catalogs.json` (sugerido)
\- Atualização feita por você/seu colega via commit/redeploy (V1) \*\*ou\*\* endpoint admin (V2) se vocês decidirem persistência externa (DB/kv-store).

\### Estrutura sugerida (catalogs.json)
\*\*Chaves principais\*\*:

\- `clients[]`: mapeia nome exibido no App → IDs e configurações.

\- `vehicle_catalog`: lista de fabricantes/modelos aceitos no App e seus IDs/descrições para cadastro no HTML5.

\- `comment_templates`: templates de comentário para SB/GS.

\*\*Exemplo (mínimo)\*\*:

```json
{
  "version": "2026-01-08",
  "clients": [
    {
      "client_key": "translima",
      "client_name": "TransLima",
      "client_id": 218572,
      "monitor": {
        "schemes": [
          { "scheme_id": 5592, "label": "Padrão", "is_default": true },
          { "scheme_id": 7777, "label": "Refrigerado", "is_default": false }
        ]
      },
      "html5": {
        "client_id": 218572
      }
    }
  ],
  "vehicle_catalog": {
    "manufacturers": [
      { "key": "volkswagen", "name": "Volkswagen" },
      { "key": "scania", "name": "Scania" }
    ],
    "models": [
      { "key": "vw_17_230", "manufacturer_key": "volkswagen", "name": "17.230", "vehicle_type_id": 1234 }
    ]
  },
  "comment_templates": {
    "scheme_builder": "Installed {{date_dd_mmm}} by {{tech_first_name}}",
    "g_sensor": "G-Sensor: {{label_position}} - {{harness_position}}"
  }
}
```

\### Regras de resolução (Backend)
\- Ao receber o submit do técnico, o Backend deve:
1) Resolver `client_id` a partir do cliente selecionado (`client_key` ou `client_name`).

2) Resolver `scheme_id`:
   \- Se o cliente tem 1 scheme → usar ele.
   \- Se tem 2+ schemes → usar o `is_default=true` \*\*ou\*\* aplicar uma regra de seleção (ex.: por tipo de veículo/grupo) \*\*ou\*\* pedir ao técnico escolher um “perfil” simples (dropdown com labels) — somente se necessário.

3) Resolver `vehicle_type_id`/modelo:
   \- Técnico escolhe `manufacturer` e `model` (chaves do catálogo).
   \- Backend converte para o ID/valor usado no HTML5.

\### Regras “hard stop” disciplinar (serial não registrado)
\- Em INSTALL e MAINT_SWAP:
  \- Se lookup do serial no HTML5 falhar (serial não existe / não testado) → \*\*SERIAL_NOT_REGISTERED\*\* e a instalação não prossegue até correção interna.

\### Comentários dinâmicos (SB/GS)
\- \*\*SB\*\*: `Installed {{date_dd_mmm}} by {{tech_first_name}}`
  \- `tech_first_name`: pegar o primeiro token do nome do técnico.
  \- `date_dd_mmm`: formatar em PT-BR (ex.: `08/jan`) ou padrão acordado com a diretoria.

\- \*\*GS\*\*: `G-Sensor: {{label_position}} - {{harness_position}}`
  \- `label_position`: posição do rótulo (ex.: “UP”, “FRONT”, etc.)
  \- `harness_position`: posição do chicote.

\### Operação futura (V2) — atualização sem redeploy
\- Se vocês quiserem atualizar DE/PARA sem redeploy, criar um endpoint admin para \*\*upload do JSON\*\* e persistir em storage externo (DB/kv-store) com versionamento e rollback.
