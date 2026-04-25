# project-orchestration Plugin

Multi-agent project orchestration for Claude Code. Provides the meta-agent layer for architecture specs, task decomposition, agent fleet generation, and dispatch coordination.

## Quick Start

Run `/project-orchestration:setup` in your project to:
1. Detect your project structure (backend path, frontend path, stack)
2. Copy rules to `.claude/rules/` with paths configured for your layout
3. Optionally scaffold a `CLAUDE.md` with stack info

## Agents

### Meta-agents (included)

| Agent | Role | Model |
|-------|------|-------|
| `orchestrator` | Discussion + dispatch; drives task lists to completion | opus |
| `architect` | Discovery conversation → architecture spec | opus |
| `decomposer` | Spec → parallelizable task list | opus |
| `agent-creator` | Spec → project-specific implementation agents | opus |
| `cleanup-engineer` | Dead code removal, codebase shrinking | sonnet |
| `historian` | Context recovery across sessions | sonnet |

### Implementation agents (generated per-project)

**Horizontal (layer-based):** `infra-engineer`, `domain-engineer`, `api-engineer`

**Vertical (feature-based):** `chat-engineer`, `auth-engineer`, `billing-engineer`, `dashboard-engineer`

The `agent-creator` generates these from your architecture spec's bounded contexts.

**Constraint:** The orchestrator runs as the root Claude Code session. Sub-agents cannot spawn other sub-agents, so only the root session can dispatch.

## Workflow

```
user ↔ orchestrator (root) → architect → spec
                           → agent-creator → implementation fleet  
                           → decomposer → task list
                           → implementation agents (parallel)
```

The orchestrator is the root session. In discussion mode it brainstorms; in execution mode it dispatches. Sub-agents (architect, decomposer, implementation agents) cannot spawn other agents.

## Document conventions

- `docs/specs/<feature>.md` — architect output, decomposer input
- `docs/tasks/<feature>.md` — decomposer output, orchestrator input
- `.claude/agents/<name>.md` — agent-creator output, orchestrator dispatch target

## Superpowers integration

If the `superpowers` plugin is installed, the orchestration agents reference its skills:

| Agent | Skill |
|-------|-------|
| architect | `superpowers:brainstorming` |
| decomposer | `superpowers:writing-plans` |
| orchestrator | `superpowers:dispatching-parallel-agents`, `superpowers:verification-before-completion` |
| cleanup-engineer | `superpowers:systematic-debugging` |
| agent-creator | `superpowers:writing-skills` |

Skills are referenced, not duplicated. If superpowers is not installed, agents are self-contained.

## Dispatch logging

A hook on the Agent tool logs dispatches to `.claude/dispatch-log.jsonl`:

```jsonl
{"ts":"...","event":"start","tool_use_id":"...","agent":"infra-engineer","task":"T-1","description":"..."}
{"ts":"...","event":"end","tool_use_id":"...","agent":"infra-engineer","status":"returned","duration_s":42}
```

The orchestrator uses bracketed task-id prefixes in dispatch descriptions (`[T-1] Build thing`) for filtering.

Query via `history.sh`:
```bash
bash .claude/scripts/history.sh dispatches --task T-1
bash .claude/scripts/history.sh dispatches --agent infra-engineer --since 7
```

## Rules (templates)

The `rules/` directory contains rule templates organized by stack:

```
rules/
├── common/      # universal (coding-style, testing, security, git, etc.)
├── typescript/  # extends common for TS/JS
├── nestjs/      # extends typescript for Nest backends
└── react/       # extends typescript for React frontends
```

**These are templates, not ready-to-use rules.** The `paths:` frontmatter uses example paths like `src/backend/**/*.ts`. Run `/project-orchestration:setup` to copy them to your project's `.claude/rules/` with paths rewritten for your layout.

If your project doesn't use Nest or React, the setup skill removes inapplicable rule sets.

## Scripts

- `scripts/dispatch-hook.py` — PreToolUse/PostToolUse hook for Agent dispatch logging
- `scripts/history.sh` — Query sessions, dispatches, memory
- `scripts/log-dispatch.sh` — Manual dispatch log operations (verdict logging)
- `scripts/sweep-dispatch-orphans.sh` — SessionStart hook; marks orphaned dispatches

## Skills

| Skill | Purpose |
|-------|---------|
| `setup` | Configure plugin for new project — detect structure, copy rules, rewrite paths |
| `adr-writer` | Create/update Architecture Decision Records with proper structure |
| `context-tiering` | Decide where knowledge belongs (rule file vs CLAUDE.md vs rulebook vs ADR) |

## Templates

The `templates/` directory contains document templates:

| Template | Used by | Output |
|----------|---------|--------|
| `adr.md` | adr-writer skill | `docs/architecture/*.adr.md` |
| `spec.md` | architect agent | `docs/specs/*.md` |
| `tasks.md` | decomposer agent | `docs/tasks/*.md` |
| `agent.md` | agent-creator agent | `.claude/agents/*.md` |

## Rulebooks

The `rulebooks/` directory contains normative reference material:

| Rulebook | Purpose |
|----------|---------|
| `agent-context-management.rulebook.md` | Where project knowledge belongs (tiers, placement rules) |
| `memory-patterns.rulebook.md` | How to structure cross-session memory |
| `session-recovery.rulebook.md` | How to recover context from previous sessions |

## Hook templates

The `hooks/templates/` directory contains pre-built hooks:

| Hook | Trigger | Purpose |
|------|---------|---------|
| `console-log-warn.json` | PostToolUse:Edit | Warn about console.log |
| `typescript-check.json` | PostToolUse:Edit | Run tsc after edits |
| `prettier-format.json` | PostToolUse:Edit | Auto-format with Prettier |
| `secret-scan.json` | PostToolUse:Write | Scan for hardcoded secrets |

Copy hook configs to your project's `.claude/hooks/hooks.json` or user-level `~/.claude/settings.json`.

## Installation

Copy or symlink to `~/.claude/plugins/project-orchestration/` or install via plugin manager when available.

## Usage

Invoke agents via the Agent tool with `subagent_type`:

```
Agent({
  subagent_type: "orchestrator",
  description: "Continue task execution",
  prompt: "..."
})
```

Or let the orchestrator dispatch implementation agents from a task list.
