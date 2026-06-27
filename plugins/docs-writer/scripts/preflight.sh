#!/usr/bin/env bash
# Preflight check para o plugin docs-writer.
# Valida: python3, PyYAML, Environments.yaml + bloco atlassian (cloudId, jira.boards, confluence.spaces).
# A dependencia atlassian e OBRIGATORIA para docs-writer (fontes Jira e Confluence).
# Usage:
#   bash preflight.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

ERRORS=0

fail() {
  echo "ERROR: $*" >&2
  ERRORS=$((ERRORS + 1))
}

# ── python3 ────────────────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
  fail "'python3' not found."
fi

# ── PyYAML ────────────────────────────────────────────────────────────────────
if ! python3 -c "import yaml" 2>/dev/null; then
  fail "PyYAML not installed. Run: pip install pyyaml"
fi

# ── Environments.yaml ─────────────────────────────────────────────────────────
ENV_FILE="Environments.yaml"
TEMPLATE="Environments-template.yaml"

if [[ ! -f "$ENV_FILE" ]]; then
  fail "$ENV_FILE not found. Copy from $TEMPLATE and fill in."
fi

# ── Validar bloco atlassian (obrigatorio) ─────────────────────────────────────
python3 << 'PY'
import sys

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML required. Run: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

with open("Environments.yaml") as f:
    cfg = yaml.safe_load(f) or {}

atlassian = cfg.get("atlassian") or {}

cloud_id = atlassian.get("cloudId")
if not cloud_id or str(cloud_id).startswith("<"):
    print("ERROR: atlassian.cloudId missing or not filled in Environments.yaml", file=sys.stderr)
    sys.exit(1)

boards = (atlassian.get("jira") or {}).get("boards") or []
if not boards or not boards[0].get("key"):
    print("ERROR: atlassian.jira.boards[0].key missing in Environments.yaml", file=sys.stderr)
    sys.exit(1)

spaces = (atlassian.get("confluence") or {}).get("spaces") or []
if not spaces or not spaces[0].get("key"):
    print("ERROR: atlassian.confluence.spaces[0].key missing in Environments.yaml", file=sys.stderr)
    sys.exit(1)

print(f"OK: atlassian.cloudId={cloud_id}")
print(f"OK: atlassian.jira.boards[0].key={boards[0]['key']}")
print(f"OK: atlassian.confluence.spaces[0].key={spaces[0]['key']}")
PY

STATUS=$?
if [[ $STATUS -ne 0 ]]; then
  ERRORS=$((ERRORS + 1))
fi

# ── Verificar .docs gravavel ───────────────────────────────────────────────────
DOCS_DIR=".docs"
if [[ -e "$DOCS_DIR" && ! -d "$DOCS_DIR" ]]; then
  fail ".docs existe mas nao e um diretorio."
fi

if [[ -d "$DOCS_DIR" && ! -w "$DOCS_DIR" ]]; then
  fail ".docs existe mas nao tem permissao de escrita."
fi

# ── Resultado ─────────────────────────────────────────────────────────────────
if [[ $ERRORS -gt 0 ]]; then
  echo "" >&2
  echo "Preflight failed with $ERRORS error(s). Fix the issues above and retry." >&2
  exit 1
fi

echo "OK: docs-writer preflight passed"
