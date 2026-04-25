#!/usr/bin/env bash
# Find dispatch_start events with no matching dispatch_end and append a
# synthetic dispatch_end with status=abandoned.
#
# Uses two signals to decide whether a start is truly stale:
#
#   1. Session liveness (primary, when start has session_id). Reads the
#      session jsonl at ~/.claude/projects/-<project-slug>/<sid>.jsonl
#      and checks its mtime. If the file has been written in the last
#      --session-liveness-minutes, the session is considered alive and the
#      dispatch is SKIPPED — it may still be legitimately running.
#
#   2. Wall-clock cutoff (fallback, when start has no session_id). Only
#      sweep if the start is older than --older-than-minutes. Applies to
#      legacy rows from before the hook started capturing session_id.
#
# Pairing key: tool_use_id when present, else (task,agent).
#
# Usage:
#   sweep-dispatch-orphans.sh [--session-liveness-minutes N=5]
#                             [--older-than-minutes N=30]
#                             [--dry-run]
#
# Exit 0 regardless of whether anything was swept. Safe to run frequently.

set -u

# Derive project root from git or script location
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$(dirname "$(realpath "$0")")")")"
LOG_FILE="${PROJECT_ROOT}/.claude/dispatch-log.jsonl"

# Derive Claude Code project slug from absolute path (replace / with -)
PROJECT_SLUG="$(echo "$PROJECT_ROOT" | sed 's|^/||; s|/|-|g')"
SESSION_DIR="${HOME}/.claude/projects/-${PROJECT_SLUG}"
LIVENESS_MIN=5
WALLCLOCK_MIN=30
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --session-liveness-minutes) LIVENESS_MIN="$2"; shift 2 ;;
    --older-than-minutes)       WALLCLOCK_MIN="$2"; shift 2 ;;
    --dry-run)                  DRY_RUN=1; shift ;;
    *) echo "error: unknown option: $1" >&2; exit 2 ;;
  esac
done

[ -f "$LOG_FILE" ] || { echo "no dispatch log" >&2; exit 0; }

python3 - "$LOG_FILE" "$SESSION_DIR" "$LIVENESS_MIN" "$WALLCLOCK_MIN" "$DRY_RUN" <<'PY'
import json, os, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

log_file = Path(sys.argv[1])
session_dir = Path(sys.argv[2])
liveness_sec = int(sys.argv[3]) * 60
wallclock_min = int(sys.argv[4])
dry_run = sys.argv[5] == "1"

rows = []
for line in log_file.read_text().splitlines():
    line = line.strip()
    if not line:
        continue
    try:
        rows.append(json.loads(line))
    except json.JSONDecodeError:
        continue


def key(row):
    tid = row.get("tool_use_id") or ""
    if tid:
        return ("tid", tid)
    return ("ta", row.get("task", ""), row.get("agent", ""))


ended = {key(r) for r in rows if r.get("event") == "dispatch_end"}

now = datetime.now(timezone.utc)
wall_cutoff = now - timedelta(minutes=wallclock_min)


def session_alive(session_id):
    """Return True/False if we can tell; None if session_id is unknown."""
    if not session_id:
        return None
    f = session_dir / f"{session_id}.jsonl"
    if not f.exists():
        return False
    age_sec = now.timestamp() - f.stat().st_mtime
    return age_sec < liveness_sec


orphans = []
skipped_live = 0
seen = set()
for r in rows:
    if r.get("event") != "dispatch_start":
        continue
    k = key(r)
    if k in ended or k in seen:
        continue
    try:
        ts = datetime.strptime(r["ts"], "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=timezone.utc
        )
    except (KeyError, ValueError):
        continue
    sid = r.get("session_id") or ""
    alive = session_alive(sid)
    if alive is True:
        skipped_live += 1
        continue
    if alive is None and ts > wall_cutoff:
        # No session_id to check AND start is too recent for wall-clock fallback.
        continue
    orphans.append(r)
    seen.add(k)

if not orphans:
    msg = "no orphans"
    if skipped_live:
        msg += f" ({skipped_live} skipped — source session still live)"
    print(msg)
    sys.exit(0)

sweep_ts = now.strftime("%Y-%m-%dT%H:%M:%SZ")
lines = []
for o in orphans:
    entry = {
        "event": "dispatch_end",
        "status": "abandoned",
        "task": o.get("task", ""),
        "agent": o.get("agent", ""),
        "tool_use_id": o.get("tool_use_id", ""),
        "session_id": o.get("session_id", ""),
        "swept_from_start_ts": o.get("ts", ""),
        "ts": sweep_ts,
    }
    lines.append(json.dumps(entry, separators=(",", ":")))

header = f"found {len(orphans)} orphan start(s)"
if skipped_live:
    header += f"; {skipped_live} skipped (source session live)"
print(header)
for line in lines:
    print(("DRY: " if dry_run else "SWEEP: ") + line)

if not dry_run:
    with log_file.open("a") as fh:
        for line in lines:
            fh.write(line + "\n")
PY
