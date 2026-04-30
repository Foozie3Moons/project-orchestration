# project-orchestration

Multi-agent project orchestration for Claude Code. Provides meta-agents, workflow skills, rule templates, and document conventions for running complex projects with parallel agent dispatch.

## Why use this

**Scale beyond a single context window.** Large projects exceed what one agent can hold in context. This plugin splits work across focused sub-agents, each with only the context they need.

**Parallelize implementation.** Independent tasks dispatch to separate agents simultaneously. A 10-task feature that takes 2 hours sequentially takes 30 minutes with 4 parallel agents.

**Enforce consistency.** Rule templates and agent definitions ensure every agent follows the same patterns, conventions, and boundaries. No drift between what agent A and agent B produce.

**Separate planning from execution.** Meta-agents (architect, decomposer) think through the problem. Implementation agents execute. The orchestrator coordinates. Clean separation of concerns.

**Recover context across sessions.** The historian can answer "what did we decide?" and "what was I working on?" by searching session history, dispatch logs, and memory.

**Exclusive file ownership.** Each task owns specific files. No merge conflicts between parallel agents. The decomposer enforces this at planning time.

### Example workflows

---

#### Frontend restructure (17 parallel tasks)

**Scenario:** Restructure a React dashboard from ad-hoc layout into layered architecture (api, pages, layouts, components, molecules).

**Workflow:**
1. Architect produces spec defining the target layer structure
2. Decomposer generates 17 independent file-move tasks with exclusive ownership
3. Orchestrator dispatches 3 vertical agents simultaneously: `dashboard-engineer`, `chat-engineer`, `settings-engineer`
4. ~12 minutes wall-clock vs ~2 hours sequential

Each agent owns a feature slice. No merge conflicts because file ownership is exclusive.

---

#### Backend layering (8 parallel tasks)

**Scenario:** Reorganize Nest modules into five layers: `api/` → `use-case/` → `application/` → `data-access/` → `domain/`.

**Workflow:**
1. ADR documents the layer boundaries and import direction
2. Decomposer assigns one module per task to `domain-engineer`
3. 8 tasks dispatch simultaneously
4. One task blocks on a missing dependency — orchestrator auto-retries after prerequisite completes

Strict layer direction enforced by rules copied during setup.

---

#### Full feature build (10 tasks, dependency-aware)

**Scenario:** Build an activity log feature showing all agent executions across multiple entry points.

**Workflow:**
1. Architect runs discovery → outputs `docs/specs/activity-log.md`
2. Agent-creator generates `activity-engineer` from the spec
3. Decomposer produces 10 tasks with explicit dependencies (T1/T2/T3 parallel, T4 waits on T3)
4. Orchestrator dispatches respecting dependencies
5. End-to-end in ~3 hours

The dispatch log tracks which tasks are running, blocked, or complete.

---

#### Context recovery

Specs and dispatch logs serve as persistent context. The historian can answer "what was I working on?" by searching logs and documents — no need to re-explain state when resuming.

---

## What it does

```
                              ┌→ architect → spec
                              │
user ↔ orchestrator (root) ───┼→ decomposer → tasks
       [discuss | dispatch]   │
                              └→ implementation agents (parallel)
```

The orchestrator is the root Claude Code session. In **discussion mode** it thinks through ideas with you. In **execution mode** it dispatches sub-agents and drives tasks to completion.

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

### Meta-agents (included in plugin)

These agents produce documents and dispatch work — they don't write implementation code.

| Agent | Purpose |
|-------|---------|
| `orchestrator` | Discussion partner + dispatch driver (root session) |
| `architect` | Discovery conversation → architecture spec |
| `decomposer` | Spec → parallelizable task list |
| `agent-creator` | Spec → project-specific implementation agents |
| `cleanup-engineer` | Dead code removal, codebase shrinking |
| `historian` | Context recovery across sessions |

### Implementation agents (generated per-project)

The `agent-creator` generates these based on your architecture spec. Two patterns:

**Horizontal (layer-based)** — owns a layer across the whole codebase:

| Agent | Purpose |
|-------|---------|
| `infra-engineer` | Core infrastructure, config, database, build setup |
| `domain-engineer` | Domain modules, repositories, services |
| `api-engineer` | REST/GraphQL endpoints, controllers, DTOs |

**Vertical (feature-based)** — owns a feature across the full stack:

| Agent | Purpose |
|-------|---------|
| `chat-engineer` | Chat feature end-to-end (backend + frontend) |
| `auth-engineer` | Authentication flow end-to-end |
| `billing-engineer` | Billing/payments feature end-to-end |
| `dashboard-engineer` | Dashboard CRUD features full-stack |

The agent-creator decides horizontal vs vertical based on your spec's bounded contexts. Vertical agents are common when a feature has tight coupling across layers.

**Important:** The orchestrator runs as the root Claude Code session, not as a sub-agent. Sub-agents cannot spawn other sub-agents, so the orchestrator must be the main session to dispatch implementation agents.

Dispatch sub-agents via the Agent tool:

```javascript
Agent({
  subagent_type: "architect",
  description: "Design auth feature",
  prompt: "Run discovery for user authentication. Output spec to docs/specs/auth.md."
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
→ (Root session) Dispatch architect agent
→ Discovery conversation (pain point, constraints, stack)
→ Output: docs/specs/auth.md
```

### 2. Agent generation (optional)

```
→ (Root session) Dispatch agent-creator with the spec
→ Output: .claude/agents/auth-engineer.md (and others as needed)
```

### 3. Decomposition

```
→ (Root session) Dispatch decomposer with the spec
→ Output: docs/tasks/auth.md (phased, parallelizable tasks)
```

### 4. Execution

```
User: "go" or "dispatch"
→ Root session becomes the orchestrator
→ Reads task list, dispatches implementation agents
→ Verifies acceptance criteria after each task
→ Commits per task
→ Reports progress
```

The root session (orchestrator) is the only agent that can dispatch sub-agents. The architect, decomposer, and implementation agents are all dispatched as sub-agents and cannot spawn further agents.

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
