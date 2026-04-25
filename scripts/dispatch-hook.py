#!/usr/bin/env python3
"""
PreToolUse / PostToolUse hook for the Agent tool.

Auto-logs every Agent dispatch to .claude/dispatch-log.jsonl so the orchestrator
no longer has to call log-dispatch.sh start/end manually. Pairing is guaranteed
by tool_use_id regardless of whether the orchestrator remembers.

Task-id convention: orchestrator puts it in the Agent tool's `description` as a
bracketed prefix, e.g. description="[T-1] Build thing". The hook parses that;
descriptions without a bracketed prefix log with task="".

Input: Claude Code hook JSON on stdin.
Output: appends one JSONL line to .claude/dispatch-log.jsonl.
Exit: always 0 — never blocks the Agent call.
"""
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def get_project_root() -> Path:
    """Get project root via git, fall back to script location."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True,
        )
        return Path(result.stdout.strip())
    except (subprocess.CalledProcessError, FileNotFoundError):
        # Fall back to two levels up from this script
        return Path(__file__).resolve().parent.parent.parent


LOG_FILE = get_project_root() / ".claude" / "dispatch-log.jsonl"
TASK_ID_RE = re.compile(r"^\s*\[([^\]]+)\]")


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    if data.get("tool_name") != "Agent":
        return 0

    event_name = data.get("hook_event_name", "")
    tool_input = data.get("tool_input") or {}
    agent = tool_input.get("subagent_type") or ""
    description = tool_input.get("description") or ""

    match = TASK_ID_RE.match(description)
    task = match.group(1) if match else ""

    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    base = {
        "task": task,
        "agent": agent,
        "tool_use_id": data.get("tool_use_id", ""),
        "session_id": data.get("session_id", ""),
        "ts": ts,
    }

    if event_name == "PreToolUse":
        entry = {"event": "dispatch_start", **base}
    elif event_name == "PostToolUse":
        response = data.get("tool_response") or {}
        entry = {
            "event": "dispatch_end",
            "status": "returned",
            **base,
            "tokens": response.get("totalTokens"),
            "tool_uses": response.get("totalToolUseCount"),
        }
    else:
        return 0

    with LOG_FILE.open("a") as fh:
        fh.write(json.dumps(entry, separators=(",", ":")) + "\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
