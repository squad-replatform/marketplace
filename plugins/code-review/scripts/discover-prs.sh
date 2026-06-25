#!/usr/bin/env bash
# Discover open PRs (including drafts) linked to a Jira key.
# Primary: gh search prs by title. Fallback: by body (when --match body is passed).
# Usage:
#   discover-prs.sh <JIRA-KEY>            # search in title
#   discover-prs.sh <JIRA-KEY> --body     # search in body (fallback)
# Outputs: JSON array of matching PRs to stdout.
# Requires: gh CLI, python3, PyYAML, Environments.yaml at repo root.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if [[ $# -lt 1 ]]; then
  echo "Usage: discover-prs.sh <JIRA-KEY> [--body]" >&2
  exit 1
fi

JIRA_KEY="$1"
MATCH_FIELD="title"
if [[ "${2:-}" == "--body" ]]; then
  MATCH_FIELD="body"
fi

# ── Validate Jira key format ──────────────────────────────────────────────────
if ! [[ "$JIRA_KEY" =~ ^[A-Z]+-[0-9]+$ ]]; then
  echo "ERROR: '$JIRA_KEY' does not look like a Jira key (e.g. JGR-960)." >&2
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

ORG="${GITHUB_ORG:-naturacode}"

# ── Search PRs ────────────────────────────────────────────────────────────────
# gh search prs returns open PRs by default; --state open is explicit for clarity.
# Draft PRs are included in open state.
RAW="$(gh search prs "$JIRA_KEY" \
  --owner "$ORG" \
  --state open \
  --match "$MATCH_FIELD" \
  --json repository,number,title,isDraft,url 2>/dev/null || echo '[]')"

# Post-filter: keep only PRs whose title/url actually contain the key
# (gh search can return partial matches when key has a hyphen like JGR-960 → JGR)
python3 - "$JIRA_KEY" <<'PY'
import sys, json, re

key = sys.argv[1]
pattern = re.compile(re.escape(key), re.IGNORECASE)

try:
    prs = json.loads(sys.stdin.read())
except json.JSONDecodeError:
    prs = []

matched = [pr for pr in prs if pattern.search(pr.get("title", "") + " " + pr.get("url", ""))]
print(json.dumps(matched, indent=2))
PY
