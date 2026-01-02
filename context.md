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



