#!/usr/bin/env bash
set -euo pipefail

TS="$(date +%Y-%m-%d_%H%M%S)"
SNAP="sessions/vm/${TS}_snapshot.md"

MB_DIR="${MB_DIR:-$HOME/monitor-backend}"

# Função simples pra reduzir risco de vazar tokens em logs (se existirem)
redact() {
  sed -E \
    -e 's/(session_token["=: ]+)[A-Za-z0-9_-]+/\1<REDACTED>/g' \
    -e 's/([A-Fa-f0-9]{32,})/<REDACTED_HEX>/g'
}

{
  echo "# VM Snapshot - ${TS}"
  echo

  echo "## monitor-backend (repo na VM)"
  if [ -d "$MB_DIR/.git" ]; then
    echo "- path: $MB_DIR"
    echo "- branch: $(cd "$MB_DIR" && git rev-parse --abbrev-ref HEAD)"
    echo "- sha: $(cd "$MB_DIR" && git rev-parse HEAD)"
    echo
    echo "### git status -sb"
    (cd "$MB_DIR" && git status -sb)
  else
    echo "- ERRO: não achei repo em $MB_DIR (defina MB_DIR ou ajuste o caminho)"
  fi

  echo
  echo "## systemd worker (status resumido)"
  sudo systemctl status monitor-schemebuilder-worker --no-pager -l | head -n 60 | redact

  echo
  echo "## systemd worker (paths — sem conteúdo sensível)"
  sudo systemctl show monitor-schemebuilder-worker -p FragmentPath -p DropInPaths --no-pager | redact

  echo
  echo "## last logs (últimas 40 linhas, com redaction)"
  sudo journalctl -u monitor-schemebuilder-worker -n 40 --no-pager -o cat | redact

} > "$SNAP"

git add "$SNAP"
git commit -m "sessions: vm snapshot ${TS}"
git push

echo "OK: publicado $SNAP"
