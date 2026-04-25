---
name: adr-writer
description: Create or update Architecture Decision Records with proper structure, status tracking, and cross-references.
---

You are writing an Architecture Decision Record (ADR). ADRs lock specific architectural decisions with rationale so future readers understand why the system is shaped the way it is.

# When to write an ADR

Write an ADR when:
- A decision affects multiple modules or agents
- The decision has long-term consequences that shouldn't be revisited casually
- Other documents need to reference "why we do it this way"
- You're resolving a debate and want to close it permanently

Do NOT write an ADR for:
- Feature specs (use `docs/specs/`)
- Task breakdowns (use `docs/tasks/`)
- Quick reference rules (use `.claude/rules/`)
- Temporary decisions that will change soon

# Discovery before writing

Before writing, gather:

1. **The decision itself** — what are we deciding?
2. **The context** — what problem triggered this? What constraints exist?
3. **Alternatives considered** — what other options were on the table?
4. **Why this choice** — what made this the right call?
5. **Consequences** — what becomes easier? What becomes harder?

If any of these are unclear, ask the user before writing.

# Structure

Use this structure:

```markdown
# <Title>

## Status

PROPOSED | ACCEPTED | SUPERSEDED

**Date:** YYYY-MM-DD

## Context

<Problem statement, constraints, alternatives considered>

## Decisions

### D1: <Decision title>

<What we decided and why>

### D2: <Decision title>

(Continue for each discrete decision)

## Consequences

<Implications, tradeoffs, risks>

## References

- `<doc.md>` — <relationship>
```

# Writing rules

1. **Number your decisions.** Other docs reference them as "per ADR §D1".

2. **Forward-looking language.** Describe the architecture as it is or will be, not the migration.

3. **No file paths.** Use class names, layer names, concepts. Paths rot; concepts don't.

4. **Status is mandatory.** PROPOSED = under discussion. ACCEPTED = in effect. SUPERSEDED = replaced.

5. **Date is mandatory.** Readers need to know how old this is.

6. **Link related docs.** If a rulebook implements this ADR, link it. If this supersedes another ADR, link it.

# Workflow

1. Ask user what decision needs documenting (if not clear from context)
2. Gather context — read relevant code, ask clarifying questions
3. Draft the ADR with all sections
4. Show the draft, ask for corrections
5. Write to `docs/architecture/<name>.adr.md`
6. Update any docs that should reference this ADR

# Filename convention

`docs/architecture/<name>.adr.md`

The `.adr.md` suffix distinguishes ADRs from specs and rulebooks:
- `<name>.adr.md` — Architecture Decision Record
- `<name>.rulebook.md` — Normative rulebook (rules other docs cite)
- `<name>.md` — General documentation

# Updating existing ADRs

When updating an ADR:
- If minor clarification: edit in place, update date
- If significant change: consider SUPERSEDED + new ADR
- Never silently change a decision others may be relying on

# Template reference

See `templates/adr.md` in this plugin for the full template with examples.
