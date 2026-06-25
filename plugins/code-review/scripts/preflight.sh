#!/usr/bin/env bash
# Preflight check for the code-review plugin.
# Validates: gh CLI, git, python3, PyYAML, github.token in Environments.yaml.
# For Jira context (optional): validates atlassian.cloudId when CHECK_ATLASSIAN=1.
# Usage:
#   bash preflight.sh                   # gh + github.token only
#   CHECK_ATLASSIAN=1 bash preflight.sh # also validates atlassian block
# Self-contained: does not call other plugins' preflight scripts.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

ERRORS=0

fail() {
  echo "ERROR: $*" >&2
  ERRORS=$((ERRORS + 1))
}

# ── Tools ─────────────────────────────────────────────────────────────────────
if ! command -v gh &>/dev/null; then
  fail "'gh' CLI not found. Install from https://cli.github.com/"
fi

if ! command -v git &>/dev/null; then
  fail "'git' not found."
fi

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

python3 - <<PY
import sys
try:
    import yaml
except ImportError:
    print("ERROR: PyYAML required. Run: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

with open("$ENV_FILE") as f:
    cfg = yaml.safe_load(f) or {}

github = cfg.get("github") or {}
token = github.get("token")
if not token or str(token).startswith("<"):
    print("ERROR: github.token missing or not filled in $ENV_FILE", file=sys.stderr)
    sys.exit(1)

print(f"OK: github.token present")

import os
if os.environ.get("CHECK_ATLASSIAN") != "1":
    sys.exit(0)

# Validate Atlassian block (only when Jira context is needed)
atlassian = cfg.get("atlassian") or {}
cloud_id = atlassian.get("cloudId")
if not cloud_id or str(cloud_id).startswith("<"):
    print("ERROR: atlassian.cloudId missing in $ENV_FILE", file=sys.stderr)
    sys.exit(1)

boards = (atlassian.get("jira") or {}).get("boards") or []
if not boards or not boards[0].get("key"):
    print("ERROR: atlassian.jira.boards[0].key missing in $ENV_FILE", file=sys.stderr)
    sys.exit(1)

print(f"OK: atlassian.cloudId={cloud_id}")
print(f"OK: atlassian.jira.boards[0].key={boards[0]['key']}")
PY

if [[ $ERRORS -gt 0 ]]; then
  echo "" >&2
  echo "Preflight failed with $ERRORS error(s). Fix the issues above and retry." >&2
  exit 1
fi

echo "OK: code-review preflight passed"
