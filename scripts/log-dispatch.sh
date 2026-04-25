#!/usr/bin/env bash
# Orchestrator-side dispatch verdict logger.
#
# Dispatch start/end are now auto-logged by dispatch-hook.py on PreToolUse and
# PostToolUse of the Agent tool. The orchestrator should NOT call this script
# for routine completions — the hook handles those and tags status=returned.
#
# Use this script ONLY to attach a verdict when acceptance criteria fail or
# the agent pushed back. Appends a dispatch_verdict event that queries should
# treat as overriding the auto-logged dispatch_end status.
#
# Usage:
#   log-dispatch.sh verdict <task-id-or-tool-use-id> <blocked|failed> "<reason>"
#
# Output: JSONL to .claude/dispatch-log.jsonl

set -u

# Derive project root from git or script location
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$(dirname "$(realpath "$0")")")")"
LOG_FILE="${PROJECT_ROOT}/.claude/dispatch-log.jsonl"

die() { echo "error: $*" >&2; exit 2; }

[ $# -lt 1 ] && die "usage: log-dispatch.sh verdict <task-or-tool-use-id> <blocked|failed> \"<reason>\""

if [ "$1" != "verdict" ]; then
  die "unknown subcommand: $1 (only 'verdict' is supported; start/end are auto-logged by the Agent hook)"
fi

shift
[ $# -lt 3 ] && die "usage: log-dispatch.sh verdict <task-or-tool-use-id> <blocked|failed> \"<reason>\""

REF="$1"
STATUS="$2"
REASON="$3"

case "$STATUS" in
  blocked|failed) ;;
  *) die "status must be 'blocked' or 'failed' (got: $STATUS). 'complete' is the default — don't log a verdict for it." ;;
esac

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

python3 - "$REF" "$STATUS" "$REASON" "$TS" "$LOG_FILE" <<'PY'
import json, sys
ref, status, reason, ts, log_file = sys.argv[1:6]
entry = {
    "event": "dispatch_verdict",
    "ref": ref,
    "status": status,
    "reason": reason,
    "ts": ts,
}
with open(log_file, "a") as fh:
    fh.write(json.dumps(entry, separators=(",", ":")) + "\n")
PY
