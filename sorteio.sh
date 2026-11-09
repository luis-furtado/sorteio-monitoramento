#!/usr/bin/env bash
set -euo pipefail

# Usage: ./sorteio.sh <members_file> [state_dir]
#
# Sorteia um participante sem repetição: ninguém é sorteado de novo até que
# todos tenham sido sorteados na rodada. Ao virar a rodada, quem foi o último
# sorteado não pode ser o primeiro da rodada seguinte (evita dois cycles seguidos).
#
# Estado (por time, em <state_dir>):
#   remaining.txt  quem ainda não foi sorteado na rodada atual
#   last.txt       último sorteado
#
# Opcional: EXCLUDE (env, um nome por linha) tira essas pessoas dos candidatos,
# desde que sobre alguém na rodada. Usado pelo rerun para não repetir quem já
# foi sorteado no mesmo Cycle.

MEMBERS_FILE="${1:?Informe o arquivo de participantes. Ex: ./sorteio.sh teams/monitoramento.txt}"
[[ -f "$MEMBERS_FILE" ]] || { echo "Arquivo não encontrado: $MEMBERS_FILE" >&2; exit 1; }

TEAM_NAME="$(basename "$MEMBERS_FILE" .txt)"
STATE_DIR="${2:-.sorteio-state/${TEAM_NAME}}"
REMAINING="${STATE_DIR}/remaining.txt"
LAST="${STATE_DIR}/last.txt"
mkdir -p "$STATE_DIR"

load_members() { grep -v '^\s*#' "$MEMBERS_FILE" | grep -v '^\s*$'; }

# Nova rodada: todos os participantes
[[ -s "$REMAINING" ]] || load_members > "$REMAINING"

# Mantém só quem ainda está no arquivo de time (caso alguém tenha saído)
grep -F -x -f <(load_members) "$REMAINING" > "${REMAINING}.tmp" || true
mv "${REMAINING}.tmp" "$REMAINING"
[[ -s "$REMAINING" ]] || load_members > "$REMAINING"

# Remove os excluídos (rerun), se ainda sobrar alguém
BASE="$(cat "$REMAINING")"
if [[ -n "${EXCLUDE:-}" ]]; then
  FILTERED="$(printf '%s\n' "$BASE" | grep -v -F -x -f <(printf '%s\n' "$EXCLUDE") || true)"
  if [[ -n "$FILTERED" ]]; then
    BASE="$FILTERED"
  else
    echo "Aviso: todos que faltam na rodada estão em EXCLUDE; ignorando a exclusão." >&2
  fi
fi

# Evita repetir o último sorteado quando houver outra opção
CANDIDATES="$BASE"
if [[ -s "$LAST" ]] && [[ "$(printf '%s\n' "$BASE" | wc -l)" -gt 1 ]]; then
  CANDIDATES="$(printf '%s\n' "$BASE" | grep -v -F -x "$(cat "$LAST")" || true)"
  [[ -n "$CANDIDATES" ]] || CANDIDATES="$BASE"
fi

SORTEADO="$(printf '%s\n' "$CANDIDATES" | shuf -n 1)"

grep -v -F -x "$SORTEADO" "$REMAINING" > "${REMAINING}.tmp" || true
mv "${REMAINING}.tmp" "$REMAINING"
echo "$SORTEADO" > "$LAST"

echo "$SORTEADO"
