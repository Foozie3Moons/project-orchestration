# project-orchestration

Multi-agent project orchestration for Claude Code. Provides meta-agents, workflow skills, rule templates, and document conventions for running complex projects with parallel agent dispatch.

## What it does

```
idea → architect → spec → decomposer → tasks → orchestrator → implementation agents
```

The plugin provides:
- **Meta-agents** that produce documents and dispatch work (but don't write code)
- **Skills** for setup, ADR writing, and deciding where knowledge belongs
- **Rule templates** for TypeScript/Nest/React projects (configurable paths)
- **Document templates** for specs, tasks, ADRs, and agent definitions
- **Rulebooks** for context management, memory patterns, and session recovery
- **Hook templates** for console.log detection, TypeScript checks, formatting, secret scanning

## Installation

```bash
# Clone or copy to your plugins directory
git clone <repo> ~/.claude/plugins/project-orchestration

# Or symlink
ln -s /path/to/project-orchestration ~/.claude/plugins/project-orchestration
```

## Quick start

In any project:

```
/project-orchestration:setup
```

This will:
1. Detect your project structure (backend path, frontend path, stack)
2. Copy rules to `.claude/rules/` with paths configured for your layout
3. Optionally scaffold a `CLAUDE.md` with stack info

## Agents

| Agent | Purpose | Writes code? |
|-------|---------|--------------|
| `orchestrator` | Discussion partner + dispatch driver | No |
| `architect` | Discovery conversation → architecture spec | No |
| `decomposer` | Spec → parallelizable task list | No |
| `agent-creator` | Spec → project-specific implementation agents | No |
| `cleanup-engineer` | Dead code removal, codebase shrinking | Deletes only |
| `historian` | Context recovery across sessions | No |

Dispatch via the Agent tool:

```javascript
Agent({
  subagent_type: "orchestrator",
  description: "Continue task execution",
  prompt: "Resume work on the auth feature. Task list is in docs/tasks/auth.md."
})
```

## Skills

| Skill | Invocation | Purpose |
|-------|------------|---------|
| setup | `/project-orchestration:setup` | Configure plugin for new project |
| adr-writer | `/project-orchestration:adr-writer` | Create Architecture Decision Records |
| context-tiering | `/project-orchestration:context-tiering` | Decide where knowledge belongs |

## Workflow

### 1. Architecture

```
User: "I want to add user authentication"
→ Dispatch architect agent
→ Discovery conversation (pain point, constraints, stack)
→ Output: docs/specs/auth.md
```

### 2. Agent generation (optional)

```
→ Dispatch agent-creator with the spec
→ Output: .claude/agents/auth-engineer.md (and others as needed)
```

### 3. Decomposition

```
→ Dispatch decomposer with the spec
→ Output: docs/tasks/auth.md (phased, parallelizable tasks)
```

### 4. Execution

```
→ Dispatch orchestrator with "go" or "dispatch"
→ Orchestrator reads task list, dispatches implementation agents
→ Verifies acceptance criteria after each task
→ Commits per task
→ Reports progress
```

## Rules

Rule templates organized by stack:

```
rules/
├── common/      # Universal (coding-style, testing, security, git)
├── typescript/  # Extends common for TS/JS
├── nestjs/      # Extends typescript for Nest backends
└── react/       # Extends typescript for React frontends
```

The `setup` skill copies these to your project and rewrites the `paths:` frontmatter to match your directory structure.

## Templates

Document templates the agents use:

| Template | Agent | Output location |
|----------|-------|-----------------|
| `templates/spec.md` | architect | `docs/specs/*.md` |
| `templates/tasks.md` | decomposer | `docs/tasks/*.md` |
| `templates/agent.md` | agent-creator | `.claude/agents/*.md` |
| `templates/adr.md` | adr-writer skill | `docs/architecture/*.adr.md` |

## Rulebooks

Normative reference material:

| Rulebook | Purpose |
|----------|---------|
| `agent-context-management.rulebook.md` | Where project knowledge belongs |
| `memory-patterns.rulebook.md` | Cross-session memory structure |
| `session-recovery.rulebook.md` | How historian recovers context |

## Hook templates

Pre-built hooks in `hooks/templates/`:

| Hook | Trigger | Purpose |
|------|---------|---------|
| `console-log-warn.json` | Edit | Warn about console.log |
| `typescript-check.json` | Edit | Run tsc after edits |
| `prettier-format.json` | Edit | Auto-format with Prettier |
| `secret-scan.json` | Write | Scan for hardcoded secrets |

Copy to your `.claude/hooks/hooks.json` or `~/.claude/settings.json`.

## Dispatch logging

The plugin includes hooks that log agent dispatches to `.claude/dispatch-log.jsonl`:

```jsonl
{"ts":"...","event":"start","tool_use_id":"...","agent":"infra-engineer","task":"T-1"}
{"ts":"...","event":"end","tool_use_id":"...","status":"returned","duration_s":42}
```

Query with:

```bash
bash .claude/scripts/history.sh dispatches --task T-1
bash .claude/scripts/history.sh dispatches --agent infra-engineer --since 7
```

## Superpowers integration

If the [superpowers](https://github.com/anthropics/superpowers) plugin is installed, agents reference its skills:

| Agent | Superpowers skill |
|-------|-------------------|
| architect | `brainstorming` |
| decomposer | `writing-plans` |
| orchestrator | `dispatching-parallel-agents`, `verification-before-completion` |
| cleanup-engineer | `systematic-debugging` |
| agent-creator | `writing-skills` |

Without superpowers, agents are self-contained.

## Directory conventions

```
your-project/
├── .claude/
│   ├── agents/           # Agent definitions
│   ├── rules/            # Rule files (from setup)
│   ├── hooks/            # Hook configuration
│   ├── scripts/          # Automation (from setup)
│   └── dispatch-log.jsonl
├── docs/
│   ├── architecture/     # ADRs (*.adr.md) and rulebooks (*.rulebook.md)
│   ├── specs/            # Feature specs (architect output)
│   └── tasks/            # Task lists (decomposer output)
└── CLAUDE.md
```

## License

MIT
