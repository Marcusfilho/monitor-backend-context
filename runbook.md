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