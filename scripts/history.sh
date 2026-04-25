#!/usr/bin/env bash
# history.sh — historian tool for querying Claude Code session transcripts,
# dispatch logs, and memory files for the current project.
#
# Usage: history.sh <subcommand> [options]
#
# Subcommands:
#   sessions list [--since N]             List recent sessions
#   sessions grep <pattern> [--since N]   Full-text search across sessions
#   sessions show <session-id> [--last N] [--raw]  Dump session messages
#   dispatches [--task T] [--agent A] [--status S] [--since N]  Filter dispatch log
#   memory list                           List memory files with previews
#   memory grep <pattern>                 ripgrep across memory files
#   --help | -h                           Show this help

set -euo pipefail

# Derive project root from git or script location
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$(dirname "$(realpath "$0")")")")"

# Derive Claude Code project slug from absolute path (replace / with -)
PROJECT_SLUG="$(echo "$PROJECT_ROOT" | sed 's|^/||; s|/|-|g')"

SESSION_DIR="${HOME}/.claude/projects/-${PROJECT_SLUG}"
DISPATCH_LOG="${PROJECT_ROOT}/.claude/dispatch-log.jsonl"
MEMORY_DIR="${HOME}/.claude/projects/-${PROJECT_SLUG}/memory"

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

die() { echo "error: $*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || die "required tool not found: $1"
}

require jq

# Returns the mtime of a file as epoch seconds (portable: stat -c on Linux)
file_epoch() { stat -c '%Y' "$1" 2>/dev/null || echo 0; }

# Prints ISO-8601 timestamp from epoch
epoch_to_iso() { date -d "@$1" +"%Y-%m-%d %H:%M" 2>/dev/null || date -r "$1" +"%Y-%m-%d %H:%M"; }

# Filter file list to those modified within last N days.
# Reads filenames from stdin (one per line), echos matching ones.
filter_since() {
  local days="$1"
  local cutoff
  cutoff=$(( $(date +%s) - days * 86400 ))
  while IFS= read -r f; do
    local mtime
    mtime=$(file_epoch "$f")
    [ "$mtime" -ge "$cutoff" ] && echo "$f"
  done
}

# Extract the first human-typed user message text from a session JSONL.
# Skips tool_result list content and local-command-caveat strings.
session_first_user_message() {
  local file="$1"
  jq -r '
    select(.type == "user") |
    .message.content |
    if type == "string" then
      if startswith("<local-command-caveat") then empty
      elif startswith("<") then empty
      else .
      end
    elif type == "array" then empty
    else empty
    end
  ' "$file" 2>/dev/null | head -1 | cut -c1-80 || true
}

# ---------------------------------------------------------------------------
# subcommand: sessions list
# ---------------------------------------------------------------------------

cmd_sessions_list() {
  local since=14
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --since) since="$2"; shift 2 ;;
      *) die "unknown option: $1" ;;
    esac
  done

  local cutoff
  cutoff=$(( $(date +%s) - since * 86400 ))

  local found=0
  for f in "$SESSION_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    local mtime
    mtime=$(file_epoch "$f")
    [ "$mtime" -lt "$cutoff" ] && continue

    local session_id
    session_id=$(basename "$f" .jsonl)
    local dt
    dt=$(epoch_to_iso "$mtime")
    local preview
    preview=$(session_first_user_message "$f")
    printf "%-40s  %s  %s\n" "$session_id" "$dt" "${preview:-(no user message found)}"
    found=$(( found + 1 ))
  done

  [ "$found" -eq 0 ] && die "no sessions found in the last ${since} days"
  return 0
}

# ---------------------------------------------------------------------------
# subcommand: sessions grep
# ---------------------------------------------------------------------------

cmd_sessions_grep() {
  [ $# -lt 1 ] && die "usage: sessions grep <pattern> [--since N]"
  local pattern="$1"; shift

  local since=14
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --since) since="$2"; shift 2 ;;
      *) die "unknown option: $1" ;;
    esac
  done

  local cutoff
  cutoff=$(( $(date +%s) - since * 86400 ))

  local matched=0
  for f in "$SESSION_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    local mtime
    mtime=$(file_epoch "$f")
    [ "$mtime" -lt "$cutoff" ] && continue

    local session_id
    session_id=$(basename "$f" .jsonl)
    local date_str
    date_str=$(epoch_to_iso "$mtime" | cut -d' ' -f1)

    # grep outputs matching lines; we prefix each with session-id and date
    while IFS= read -r line; do
      echo "${session_id}  ${date_str}  ${line}"
      matched=$(( matched + 1 ))
    done < <(grep -F -- "$pattern" "$f" 2>/dev/null || true)
  done

  [ "$matched" -eq 0 ] && { echo "no matches" >&2; exit 1; }
}

# ---------------------------------------------------------------------------
# subcommand: sessions show
# ---------------------------------------------------------------------------

cmd_sessions_show() {
  [ $# -lt 1 ] && die "usage: sessions show <session-id> [--last N] [--raw]"
  local session_id="$1"; shift

  local last=0
  local raw=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --last) last="$2"; shift 2 ;;
      --raw)  raw=1; shift ;;
      *) die "unknown option: $1" ;;
    esac
  done

  local file="${SESSION_DIR}/${session_id}.jsonl"
  [ -f "$file" ] || die "session not found: $session_id"

  # Build array of formatted messages then optionally take last N
  local tmpfile
  tmpfile=$(mktemp /tmp/history_show.XXXXXX)
  trap 'rm -f "$tmpfile"' EXIT

  jq -r --argjson raw "$raw" '
    select(.type == "user" or .type == "assistant") |
    {
      role: .type,
      ts: (.timestamp // ""),
      content: (
        if .type == "user" then
          (.message.content |
            if type == "string" then .
            elif type == "array" then
              [ .[] | select(.type == "tool_result") |
                "[tool_result tool_use_id=\(.tool_use_id)]"
              ] | join("\n")
            else ""
            end
          )
        else
          (.message.content // [] |
            if $raw == 1 then
              map(
                if .type == "text" then .text
                elif .type == "thinking" then "[thinking \(.thinking | .[0:60])...]"
                elif .type == "tool_use" then "[tool_use \(.name) id=\(.id)]"
                else "[block type=\(.type)]"
                end
              ) | join("\n")
            else
              map(
                if .type == "text" then .text
                elif .type == "thinking" then "[thinking (hidden; use --raw)]"
                elif .type == "tool_use" then "[tool_use: \(.name)(\(.input | keys | join(", ")))]"
                else "[block type=\(.type)]"
                end
              ) | join("\n")
            end
          )
        end
      )
    } |
    "[\(.role) \(.ts)]\n\(.content)\n"
  ' "$file" > "$tmpfile"

  if [ "$last" -gt 0 ]; then
    # Count paragraphs (each message ends with blank line); take last N
    # Use awk to split on double-newline and take last $last blocks
    awk -v n="$last" '
      BEGIN { RS=""; ORS="\n\n" }
      { lines[NR] = $0 }
      END {
        start = (NR > n) ? NR - n + 1 : 1
        for (i = start; i <= NR; i++) print lines[i]
      }
    ' "$tmpfile"
  else
    cat "$tmpfile"
  fi
}

# ---------------------------------------------------------------------------
# subcommand: dispatches
# ---------------------------------------------------------------------------

cmd_dispatches() {
  local task_filter=""
  local agent_filter=""
  local status_filter=""
  local since=0  # 0 = no date filter

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --task)   task_filter="$2";   shift 2 ;;
      --agent)  agent_filter="$2";  shift 2 ;;
      --status) status_filter="$2"; shift 2 ;;
      --since)  since="$2";         shift 2 ;;
      *) die "unknown option: $1" ;;
    esac
  done

  [ -f "$DISPATCH_LOG" ] || die "dispatch log not found: $DISPATCH_LOG"

  local cutoff_ts=""
  if [ "$since" -gt 0 ]; then
    cutoff_ts=$(date -u -d "$since days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
      || date -u -v"-${since}d" +"%Y-%m-%dT%H:%M:%SZ")
  fi

  # Single jq pass: pair start/end by tool_use_id (falling back to task+agent),
  # apply verdict overrides, compute duration, filter. Emit TSV for shell printf.
  local tsv
  tsv=$(
    jq -rs --arg task_filter "$task_filter" \
           --arg agent_filter "$agent_filter" \
           --arg status_filter "$status_filter" \
           --arg cutoff "$cutoff_ts" '
      def keyof: if (.tool_use_id // "") != ""
                 then .tool_use_id
                 else (.task // "") + "|" + (.agent // "") end;

      . as $rows
      | ($rows | map(select(.event == "dispatch_end"))
               | map({(keyof): .}) | add // {}) as $ends
      | ($rows | map(select(.event == "dispatch_verdict"))
               | map({(.ref // ""): .}) | add // {}) as $verdicts

      | $rows
      | map(select(.event == "dispatch_start"))
      | map(
          . as $s
          | ($ends[$s | keyof]) as $e
          | ($verdicts[$s.task // ""] // $verdicts[$s.tool_use_id // ""]) as $v
          | {
              ts:     $s.ts,
              task:   ($s.task   // ""),
              agent:  ($s.agent  // ""),
              status: ($v.status // $e.status // "in-flight"),
              duration:
                (if $e
                 then (($e.ts | fromdateiso8601) - ($s.ts | fromdateiso8601))
                 else null end),
              reason: ($v.reason // "")
            }
        )
      | map(select(
          ($cutoff        == "" or .ts     >= $cutoff) and
          ($task_filter   == "" or (.task   | contains($task_filter))) and
          ($agent_filter  == "" or (.agent  | contains($agent_filter))) and
          ($status_filter == "" or (.status | contains($status_filter)))
        ))
      | sort_by(.ts)
      | .[]
      | [ .ts, .task, .agent, .status,
          (if .duration == null then "-" else "\(.duration)s" end),
          .reason ]
      | @tsv
    ' "$DISPATCH_LOG"
  )

  if [ -z "$tsv" ]; then
    echo "no matching dispatch records" >&2
    exit 1
  fi

  printf '%-20s  %-30s  %-25s  %-11s  %-7s  %s\n' "TIMESTAMP" "TASK" "AGENT" "STATUS" "DUR" "REASON"
  while IFS=$'\t' read -r ts task agent status dur reason; do
    printf '%-20s  %-30s  %-25s  %-11s  %-7s  %s\n' "$ts" "$task" "$agent" "$status" "$dur" "$reason"
  done <<< "$tsv"
}

# ---------------------------------------------------------------------------
# subcommand: memory list
# ---------------------------------------------------------------------------

cmd_memory_list() {
  [ -d "$MEMORY_DIR" ] || die "memory directory not found: $MEMORY_DIR"
  local found=0
  for f in "$MEMORY_DIR"/*.md; do
    [ -f "$f" ] || continue
    local name
    name=$(basename "$f")
    # First non-empty line as preview
    local preview
    preview=$(grep -m1 -v '^[[:space:]]*$' "$f" 2>/dev/null | sed 's/^#\+[[:space:]]*//' || true)
    printf "%-45s  %s\n" "$name" "${preview:-(empty)}"
    found=$(( found + 1 ))
  done
  [ "$found" -eq 0 ] && die "no memory files found in $MEMORY_DIR"
  return 0
}

# ---------------------------------------------------------------------------
# subcommand: memory grep
# ---------------------------------------------------------------------------

cmd_memory_grep() {
  [ $# -lt 1 ] && die "usage: memory grep <pattern>"
  local pattern="$1"

  [ -d "$MEMORY_DIR" ] || die "memory directory not found: $MEMORY_DIR"

  local matched=0
  while IFS= read -r result; do
    echo "$result"
    matched=$(( matched + 1 ))
  done < <(grep -rF -- "$pattern" "$MEMORY_DIR" 2>/dev/null || true)

  [ "$matched" -eq 0 ] && { echo "no matches" >&2; exit 1; }
}

# ---------------------------------------------------------------------------
# help
# ---------------------------------------------------------------------------

cmd_help() {
  cat <<EOF
history.sh — historian query tool for current project

Usage: history.sh <subcommand> [options]

Project: ${PROJECT_ROOT}
Sessions: ${SESSION_DIR}

Subcommands:

  sessions list [--since N]
      List recent session files. One per line:
        <session-id>  <YYYY-MM-DD HH:MM>  <first-user-message-preview>
      --since N   Filter to sessions modified in last N days (default: 14)

  sessions grep <pattern> [--since N]
      Full-text grep search across session JSONL files.
      Output: <session-id>  <date>  <matching-line>
      --since N   Same semantics as above.

  sessions show <session-id> [--last N] [--raw]
      Dump session messages in chronological order.
      Output: [role timestamp] followed by content.
      --last N    Show only last N messages.
      --raw       Include full thinking blocks; otherwise summarised.

  dispatches [--task T] [--agent A] [--status S] [--since N]
      Filter .claude/dispatch-log.jsonl. All flags optional, AND-combined.
      Output: <ts>  <task>  <agent>  <event>  <status>

  memory list
      List files under \${MEMORY_DIR} with a one-line preview.

  memory grep <pattern>
      grep across memory files. Output: <file>:<line>

  --help | -h
      Show this help.
EOF
}

# ---------------------------------------------------------------------------
# dispatch
# ---------------------------------------------------------------------------

[ $# -eq 0 ] && { cmd_help; exit 0; }

case "$1" in
  sessions)
    shift
    [ $# -eq 0 ] && die "usage: sessions <list|grep|show>"
    case "$1" in
      list)  shift; cmd_sessions_list "$@" ;;
      grep)  shift; cmd_sessions_grep "$@" ;;
      show)  shift; cmd_sessions_show "$@" ;;
      *) die "unknown sessions subcommand: $1" ;;
    esac
    ;;
  dispatches)
    shift
    cmd_dispatches "$@"
    ;;
  memory)
    shift
    [ $# -eq 0 ] && die "usage: memory <list|grep>"
    case "$1" in
      list) shift; cmd_memory_list "$@" ;;
      grep) shift; cmd_memory_grep "$@" ;;
      *) die "unknown memory subcommand: $1" ;;
    esac
    ;;
  --help|-h|help)
    cmd_help
    ;;
  *)
    die "unknown subcommand: $1 (try --help)"
    ;;
esac
