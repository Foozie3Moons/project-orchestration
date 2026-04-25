---
name: context-tiering
description: Decide where project knowledge belongs — rule files, CLAUDE.md, rulebooks, ADRs, or specs. Use when adding new conventions or deciding how to document a decision.
---

You are deciding where a piece of project knowledge belongs. Different tiers have different purposes, lifespans, and audiences.

# The tiers

| Tier | Location | Lifespan | Audience | Purpose |
|------|----------|----------|----------|---------|
| Rule files | `.claude/rules/**/*.md` | Long | Agents | Quick-reference guardrails, auto-loaded by path glob |
| CLAUDE.md | `CLAUDE.md` | Long | All agents | Project entry point, stack, commands, key conventions |
| Rulebooks | `docs/architecture/*.rulebook.md` | Long | Agents + humans | Normative reference, cited by section number |
| ADRs | `docs/architecture/*.adr.md` | Permanent | Humans + agents | Decision locks with rationale |
| Specs | `docs/specs/*.md` | Short | Architect → Decomposer | Feature design, consumed once |
| Tasks | `docs/tasks/*.md` | Short | Decomposer → Orchestrator | Execution plan, consumed once |
| Memory | `.claude/projects/*/memory/*.md` | Medium | Historian | Cross-session recall, user preferences |

# Decision tree

Ask these questions in order:

## 1. Is this a decision that needs to be locked?

**Yes → ADR**
- "We chose SQLite over Postgres because..."
- "The Anthropic SDK is only imported in one file because..."
- "We use five layers because..."

ADRs explain WHY. They're permanent records that future readers consult when they want to understand the system's shape.

## 2. Is this a normative rule that other docs cite?

**Yes → Rulebook**
- Layer dependency rules (what can import what)
- Module structure requirements
- Cross-cutting patterns that span multiple rule files

Rulebooks are reference material. They use section numbers (§3.2) so other docs can cite specific rules.

## 3. Is this a quick guardrail agents need while working?

**Yes → Rule file**
- "No barrel files"
- "Constructor injection only"
- "Use Zod for validation"

Rule files are auto-loaded based on file path globs. They're terse, actionable, and scoped to specific file types.

## 4. Is this project-level context everyone needs?

**Yes → CLAUDE.md**
- Stack (TypeScript, Nest, React, SQLite)
- Key commands (`pnpm build`, `pnpm test`)
- Environment variables
- Model strategy

CLAUDE.md is the entry point. Keep it scannable.

## 5. Is this a feature being designed?

**Yes → Spec**
- Current state, target state, constraints
- API shapes, data structures
- Decisions specific to this feature

Specs are consumed by the decomposer and go stale after implementation.

## 6. Is this a task breakdown for execution?

**Yes → Task list**
- Phased tasks with file ownership
- Acceptance criteria
- Agent assignments

Task lists are consumed by the orchestrator and go stale after execution.

## 7. Is this something to remember across sessions?

**Yes → Memory**
- User preferences discovered in conversation
- Project context not in code (who's working on what, deadlines)
- Decisions made in conversation that aren't worth an ADR

Memory is for the historian to recall later.

# Anti-patterns

**Rule file too long** → Promote to rulebook. Rule files should be <100 lines, quick to scan.

**CLAUDE.md bloated** → Extract to rulebooks or rule files. CLAUDE.md should be <200 lines.

**ADR for temporary decision** → Use a spec instead. ADRs are permanent.

**Spec kept after implementation** → Archive or delete. Specs go stale. If the decision is permanent, extract to ADR.

**Duplicated across tiers** → Single source of truth. Other docs point at the canonical location.

# Practical workflow

When adding new knowledge:

1. Check if it already exists somewhere (search before writing)
2. Use the decision tree above
3. Write in the appropriate location
4. Add cross-references from related docs
5. If promoting (rule → rulebook, spec → ADR), update references

# Cross-references

Use relative paths and be specific:

```markdown
See `docs/architecture/layering.rulebook.md` §3.2 for layer dependency rules.
Per `docs/architecture/no-orm.adr.md` D1, we use raw SQL.
```

# Template reference

See `templates/` in this plugin for templates:
- `templates/adr.md` — ADR structure
- `templates/spec.md` — Spec structure
- `templates/tasks.md` — Task list structure
- `templates/agent.md` — Agent definition structure
