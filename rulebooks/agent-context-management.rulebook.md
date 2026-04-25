# Agent Context Management Rulebook

How to structure project knowledge so agents can find and use it effectively.

## §1 Directory conventions

```
.claude/
├── agents/           # Agent definitions (one per bounded context)
├── rules/            # Quick-reference rule files (auto-loaded by path)
├── scripts/          # Automation scripts (hooks, utilities)
├── hooks/            # Hook configuration (hooks.json)
└── dispatch-log.jsonl

docs/
├── architecture/     # Long-lived: ADRs (*.adr.md) and rulebooks (*.rulebook.md)
├── specs/            # Short-lived: feature specs (architect output)
└── tasks/            # Short-lived: task lists (decomposer output)

CLAUDE.md             # Project entry point
```

## §2 Tier definitions

### §2.1 Rule files (`.claude/rules/**/*.md`)

**Purpose:** Quick guardrails auto-loaded when agents work on matching files.

**Characteristics:**
- Scoped via `paths:` frontmatter glob
- Terse and actionable
- <100 lines each
- Organized by stack: `common/`, `typescript/`, `nestjs/`, `react/`

**When to use:** For "always do X" or "never do Y" rules that agents need while editing code.

### §2.2 CLAUDE.md

**Purpose:** Project entry point. Stack, commands, key conventions.

**Characteristics:**
- <200 lines
- Always loaded
- Scannable sections

**When to use:** For context every agent needs regardless of what file they're editing.

### §2.3 Rulebooks (`docs/architecture/*.rulebook.md`)

**Purpose:** Normative reference material cited by section number.

**Characteristics:**
- Numbered sections (§1, §2.3, etc.)
- Comprehensive coverage of a domain
- Other docs cite specific sections

**When to use:** For complex rule systems that span multiple contexts (e.g., layer dependencies).

### §2.4 ADRs (`docs/architecture/*.adr.md`)

**Purpose:** Lock decisions with rationale.

**Characteristics:**
- Numbered decisions (D1, D2, etc.)
- Status tracking (PROPOSED/ACCEPTED/SUPERSEDED)
- Permanent record

**When to use:** For decisions that shouldn't be revisited casually and need explanation.

### §2.5 Specs (`docs/specs/*.md`)

**Purpose:** Feature design for implementation.

**Characteristics:**
- Current state → target state
- Consumed by decomposer
- Goes stale after implementation

**When to use:** For new features or refactors before work begins.

### §2.6 Tasks (`docs/tasks/*.md`)

**Purpose:** Execution plan for orchestrator.

**Characteristics:**
- Phased, parallelizable tasks
- Exclusive file ownership
- Consumed by orchestrator

**When to use:** After a spec is ready, before implementation begins.

## §3 Placement rules

### §3.1 No duplication

Every piece of knowledge has ONE canonical location. Other docs point to it.

Wrong:
```markdown
# In rules/common/testing.md
Use Vitest for tests.

# In CLAUDE.md
Use Vitest for tests.
```

Right:
```markdown
# In CLAUDE.md
- **Test runner:** Vitest

# In rules/common/testing.md
See `CLAUDE.md` for test runner. This file covers testing patterns.
```

### §3.2 Promote when outgrowing

| Signal | Action |
|--------|--------|
| Rule file > 100 lines | Extract to rulebook |
| CLAUDE.md > 200 lines | Extract to rulebooks or rule files |
| Spec decision is permanent | Extract to ADR |
| Memory is load-bearing | Extract to CLAUDE.md or ADR |

### §3.3 Archive when stale

Specs and task lists go stale after implementation. Options:
- Delete (if the decision is captured elsewhere)
- Move to `docs/archived/`
- Extract permanent decisions to ADRs

## §4 Cross-reference format

### §4.1 Rulebook citations

```markdown
Per §3.2 of `docs/architecture/layering.rulebook.md`, api/ cannot import data-access/.
```

### §4.2 ADR citations

```markdown
Per D1 of `docs/architecture/no-orm.adr.md`, we use raw SQL with prepared statements.
```

### §4.3 Rule file references

```markdown
See `.claude/rules/nestjs/patterns.md` §Repository Pattern for the full pattern.
```

## §5 Inheritance model

Rule files form an inheritance hierarchy:

```
common/coding-style.md
    └── typescript/coding-style.md
            ├── nestjs/coding-style.md
            └── react/coding-style.md
```

More specific files win on conflict. Each file states what it extends.

## §6 Agent context loading

When an agent is dispatched:

1. **Always loaded:** CLAUDE.md, agent's own definition
2. **Path-matched:** Rule files whose `paths:` glob matches the files being edited
3. **On demand:** Rulebooks and ADRs when the agent needs deeper context

Agents should not read entire rulebooks unless needed. Rule files are the primary interface.

## §7 Forbidden patterns

### §7.1 Structure for documenting forbidden patterns

When documenting a forbidden pattern in a rule file, use this structure:

```markdown
## <Pattern name>

Wrong pattern:

\`\`\`typescript
// example of the wrong code
\`\`\`

Why tempting: <why engineers/agents reach for this>

Failure mode: <what breaks and how>

Mechanical enforcement: <lint rule, hook, or "review only">

Correct alternative:

\`\`\`typescript
// example of the right code
\`\`\`
```

This structure ensures forbidden patterns are actionable, not just prohibitions.
