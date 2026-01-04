# RUNBOOK - Monitor Backend (VM + Host)

## Objetivo
Checklist operacional para reproduzir testes, coletar evidˆncias e manter o hist¢rico do projeto.

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
