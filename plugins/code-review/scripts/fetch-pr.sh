#!/usr/bin/env bash
# Fetch PR metadata and diff for a given owner/repo/number (or PR URL).
# Usage:
#   fetch-pr.sh <owner> <repo> <number>
#   fetch-pr.sh https://github.com/<owner>/<repo>/pull/<number>
# Outputs: metadata JSON followed by diff to stdout.
# Requires: gh CLI, python3, PyYAML (pip install pyyaml), Environments.yaml at repo root.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

# ── Parse arguments ──────────────────────────────────────────────────────────
if [[ $# -eq 1 && "$1" =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
  NUMBER="${BASH_REMATCH[3]}"
elif [[ $# -eq 3 ]]; then
  OWNER="$1"
  REPO="$2"
  NUMBER="$3"
else
  echo "Usage: fetch-pr.sh <owner> <repo> <number>" >&2
  echo "       fetch-pr.sh https://github.com/<owner>/<repo>/pull/<number>" >&2
  exit 1
fi

# ── Export GH_TOKEN from Environments.yaml ───────────────────────────────────
ENV_FILE="Environments.yaml"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found at repo root ($ROOT)." >&2
  exit 1
fi

GH_TOKEN="$(python3 - <<'PY'
import sys
try:
    import yaml
except ImportError:
    print("ERROR: PyYAML required. Run: pip install pyyaml", file=sys.stderr)
    sys.exit(1)
with open("Environments.yaml") as f:
    cfg = yaml.safe_load(f) or {}
token = (cfg.get("github") or {}).get("token")
if not token or token.startswith("<"):
    print("ERROR: github.token missing or not filled in Environments.yaml", file=sys.stderr)
    sys.exit(1)
print(token)
PY
)"
export GH_TOKEN

# ── Fetch metadata ────────────────────────────────────────────────────────────
echo "=== PR METADATA: ${OWNER}/${REPO}#${NUMBER} ==="
gh pr view "$NUMBER" \
  --repo "${OWNER}/${REPO}" \
  --json title,body,headRefName,baseRefName,isDraft,url,state

echo ""
echo "=== PR DIFF: ${OWNER}/${REPO}#${NUMBER} ==="
gh pr diff "$NUMBER" --repo "${OWNER}/${REPO}"
