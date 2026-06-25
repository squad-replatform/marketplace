#!/usr/bin/env bash
# Valida Environments.yaml antes de usar atlassian-assistant.
# Requer: python3, PyYAML (pip install pyyaml)
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

ENV_FILE="Environments.yaml"
TEMPLATE="Environments-template.yaml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Copy from $TEMPLATE and fill in." >&2
  exit 1
fi

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
if not cloud_id:
    print("ERROR: atlassian.cloudId missing in Environments.yaml", file=sys.stderr)
    sys.exit(1)

boards = (atlassian.get("jira") or {}).get("boards") or []
if not boards or not boards[0].get("key"):
    print("ERROR: atlassian.jira.boards[0].key missing in Environments.yaml", file=sys.stderr)
    sys.exit(1)

spaces = (atlassian.get("confluence") or {}).get("spaces") or []
if not spaces or not spaces[0].get("key"):
    print("ERROR: atlassian.confluence.spaces[0].key missing in Environments.yaml", file=sys.stderr)
    sys.exit(1)

print(f"OK: cloudId={cloud_id}")
print(f"OK: project={boards[0]['key']}")
print(f"OK: space={spaces[0]['key']}")
PY

echo "OK: atlassian-assistant preflight passed"
