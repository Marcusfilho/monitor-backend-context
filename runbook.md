# RUNBOOK - Monitor Backend (VM + Host)

## Objetivo
Checklist operacional para reproduzir testes, coletar evidˆncias e manter o hist¢rico do projeto.


\- garantir token válido
\- worker rodando com build atual
\- job executando e retornando resultado
\- caminho rápido para diagnosticar 403/timeout


## Rotina rápida (toda vez que for rodar jobs)

\### 1) Confirmar versão (VM)

```bash
cd ~/monitor-backend
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD
git status -sb
npm run build


---

## VM (Tunel) - Rotina padrao de teste (SB + GS)
```bash
cd ~/monitor-backend || exit 1
set -a; source ~/monitor-backend/worker_secrets.env; set +a

# For‡ar novo token (regra: token sempre via HTTP user_login)
rm -f /tmp/.session_token

# Teste SB + GS (GS_COMMAND_SYNTAX vazio se comando j  ‚ hardcoded)
CAN_HOLD=0 \
GS_ENABLE=1 GS_DELAY_MS=1500 GS_ACTION_ID=5 \
GS_COMMAND_SYNTAX='' \
WS_DEBUG=1 \
node tools/sb_run_vm.js 218572 "TransLima" 1940478 5592 "SB+GS test"


## Fechar marco — VM Snapshot Vehicle Monitor (v4.7.2)

Checklist:
1) monitor-backend (VM):
   - git pull --rebase
   - git add tools/vm_snapshot_ws_v4.js
   - git commit -m "tools: vm_snapshot_ws_v4 v4.7.2 ..."
   - git push

2) Rodar snapshot golden (VM):
   - gerar /tmp/vm_snapshot_<VID>_v4.json
   - validar:
     - parameters_tab.count_with_value > 0 OU refresh_values > 0
     - debug.params_refresh.reason = has_refresh_values|has_row_values

3) Gerar pacote do marco (VM):
   - /tmp/marco_vm_snapshot_<VID>_v4.7.2_<ts>.zip
   - incluir: tool + snapshot + ws_debug + git_status/log/diff

4) monitor-backend-context (HOST):
   - copiar ZIP para snapshots/
   - atualizar context.md + runbook.md com a seção v4.7.2
   - git add/commit/push

5) (Opcional) Host/VM:
   - manter o ZIP também arquivado localmente (backup).
   
   
   
   # RUNBOOK - Monitor Backend (VM + Host)

## Objetivo
Checklist operacional para reproduzir testes, coletar evid?ncias e manter o hist?rico do projeto.


\- garantir token v?lido
\- worker rodando com build atual
\- job executando e retornando resultado
\- caminho r?pido para diagnosticar 403/timeout


## Rotina r?pida (toda vez que for rodar jobs)

\### 1) Confirmar vers?o (VM)

```bash
cd ~/monitor-backend
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD
git status -sb
npm run build


---

## VM (Tunel) - Rotina padrao de teste (SB + GS)
```bash
cd ~/monitor-backend || exit 1
set -a; source ~/monitor-backend/worker_secrets.env; set +a

# For?ar novo token (regra: token sempre via HTTP user_login)
rm -f /tmp/.session_token

# Teste SB + GS (GS_COMMAND_SYNTAX vazio se comando j? ? hardcoded)
CAN_HOLD=0 \
GS_ENABLE=1 GS_DELAY_MS=1500 GS_ACTION_ID=5 \
GS_COMMAND_SYNTAX='' \
WS_DEBUG=1 \
node tools/sb_run_vm.js 218572 "TransLima" 1940478 5592 "SB+GS test"


## Fechar marco ? VM Snapshot Vehicle Monitor (v4.7.2)

Checklist:
1) monitor-backend (VM):
   - git pull --rebase
   - git add tools/vm_snapshot_ws_v4.js
   - git commit -m "tools: vm_snapshot_ws_v4 v4.7.2 ..."
   - git push

2) Rodar snapshot golden (VM):
   - gerar /tmp/vm_snapshot_<VID>_v4.json
   - validar:
     - parameters_tab.count_with_value > 0 OU refresh_values > 0
     - debug.params_refresh.reason = has_refresh_values|has_row_values

3) Gerar pacote do marco (VM):
   - /tmp/marco_vm_snapshot_<VID>_v4.7.2_<ts>.zip
   - incluir: tool + snapshot + ws_debug + git_status/log/diff

4) monitor-backend-context (HOST):
   - copiar ZIP para snapshots/
   - atualizar context.md + runbook.md com a se??o v4.7.2
   - git add/commit/push

5) (Opcional) Host/VM:
   - manter o ZIP tamb?m arquivado localmente (backup).


## Instalações (V1) — Checklist operacional (spec para implementação)

### Objetivo
- Rodar o fluxo ponta-a-ponta a partir de um `installation_id`.
- Evitar duplicidade (idempotência) e manter evidências (logs + snapshots).

### Pré-requisitos
- Backend online (Render) e Worker (VM) rodando com build atual.
- Token do Monitor renovado via `user_login` (worker gera session_token sempre que necessário).
- HTML5: mapeamento de endpoints de lookup/cadastro/descadastro (a implementar).

### Estados (alto nível)
- CREATED ? HTML5_DONE ? SB_RUNNING ? SB_DONE ? WAITING_REBOOT_CAN ? CAN_SNAPSHOT_READY ? CAN_APPROVED/CAN_APPROVED_OVERRIDE ? GS_DONE ? COMPLETED

### Ações que o App deve conseguir fazer (V1)
1) Criar instalação
- `POST /api/installations` (retorna `installation_id` + `installation_token`)

2) Consultar status
- `GET /api/installations/{installation_id}`

3) Pedir nova bateria de snapshot CAN (sem reexecutar SB/GS)
- `POST /api/installations/{installation_id}/actions/request-can-snapshot`

4) Aprovar CAN
- `POST /api/installations/{installation_id}/actions/approve-can`
  - body: `{ "override": false }`

5) Aprovar CAN sem validar (override)
- `POST /api/installations/{installation_id}/actions/approve-can`
  - body: `{ "override": true, "reason": "vehicle_new_no_engineering" }`

### Identificação do técnico (V1)
- CPF informado 1x por aparelho.
- Backend emite `installer_token` com validade de 30 dias.
- App salva em localStorage e reutiliza.

### Erros comuns (mensagem clara no App)
- SERIAL_NOT_REGISTERED: serial não está pré-registrado/testado.
- WS_NETWORK: VPN/DNS/rota impedindo WS.
- SB_TIMEOUT: atualização travada/sem progresso.
- CAN_NO_SIGNAL: sem valores após bateria; permitir novas tentativas no App.




## Catálogos DE/PARA — rotina de atualização (V1)

### O que é
- Arquivo `config/catalogs.json` no Backend contém:
  - lista de clientes (`client_id`),
  - schemes por cliente (um ou mais `scheme_id`),
  - catálogo de fabricantes/modelos (para cadastro no HTML5),
  - templates de comentário (SB/GS).

### Quando atualizar
- Novo cliente onboard.
- Cliente mudou o scheme (novo `scheme_id`).
- Cliente passou a ter 2 schemes (definir `is_default` e/ou regra de seleção).
- Novo fabricante/modelo liberado para cadastro.

### Como atualizar (V1)
1) Editar `config/catalogs.json` (incrementar `version`).
2) Commit + push.
3) Redeploy do Backend (ou restart do serviço, conforme infra).

### Validação rápida (checklist)
- Cliente aparece no App.
- Para o cliente, o Backend resolve:
  - `client_id`,
  - `scheme_id` default,
  - `vehicle_type_id` do modelo.
- Comentários gerados:
  - SB: `Installed dd/mmm by Nome`
  - GS: `G-Sensor: label - harness`
