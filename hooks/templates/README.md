# Hook Templates

Pre-built hooks you can add to your project's `.claude/hooks/hooks.json` or user-level `~/.claude/settings.json`.

## Available hooks

| File | Trigger | Purpose |
|------|---------|---------|
| `console-log-warn.json` | PostToolUse:Edit | Warn about console.log in edited files |
| `typescript-check.json` | PostToolUse:Edit | Run tsc after editing .ts/.tsx files |
| `prettier-format.json` | PostToolUse:Edit | Auto-format edited files with Prettier |
| `secret-scan.json` | PostToolUse:Write | Scan new files for hardcoded secrets |

## Usage

Copy the hook configuration from the template into your hooks file.

### Project-level (`.claude/hooks/hooks.json`)

```json
{
  "hooks": {
    "PostToolUse": [
      // paste hook config here
    ]
  }
}
```

### User-level (`~/.claude/settings.json`)

```json
{
  "hooks": {
    "PostToolUse": [
      // paste hook config here
    ]
  }
}
```

## Combining hooks

Multiple hooks can fire on the same trigger. They run in order. Example combining console.log warning and TypeScript check:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "grep -n 'console\\.log' \"$CLAUDE_FILE_PATH\" && echo 'WARNING: console.log found' || true",
            "timeout": 5000
          },
          {
            "type": "command", 
            "command": "if [[ \"$CLAUDE_FILE_PATH\" =~ \\.(ts|tsx)$ ]]; then npx tsc --noEmit 2>&1 | head -20; fi",
            "timeout": 30000
          }
        ]
      }
    ]
  }
}
```

## Environment variables

Hooks receive these environment variables:

| Variable | Description |
|----------|-------------|
| `CLAUDE_FILE_PATH` | Path to the file that was edited/written |
| `CLAUDE_PROJECT_ROOT` | Root directory of the project |
| `CLAUDE_TOOL_NAME` | Name of the tool that triggered the hook |

## Timeout

Set reasonable timeouts:
- Quick checks (grep): 5000ms
- TypeScript compile: 30000ms
- Full test suite: 60000ms+

If a hook times out, it's killed and the agent continues.
