# ADR Template

Architecture Decision Records lock specific decisions with rationale. Use this template when a decision:
- Affects multiple modules or agents
- Has long-term consequences
- Needs to be referenced by other documents

## Filename

`<name>.adr.md` — the `.adr.md` suffix distinguishes ADRs from specs and rulebooks.

## Structure

```markdown
# <Title>

## Status

PROPOSED | ACCEPTED | SUPERSEDED

**Date:** YYYY-MM-DD
**Supersedes:** <previous-adr.adr.md> (if applicable)
**Superseded by:** <newer-adr.adr.md> (if applicable)

## Context

<What is the problem or situation that requires a decision?>
<What constraints exist?>
<What alternatives were considered?>

## Decisions

### D1: <First decision title>

<Decision statement — what we decided and why.>

### D2: <Second decision title>

<Decision statement.>

(Continue for each discrete decision. Number them for easy reference from other documents.)

## Consequences

<What are the implications of these decisions?>
<What becomes easier? What becomes harder?>
<What risks are introduced or mitigated?>

## References

- `<other-doc.md>` — <relationship to this ADR>
- `<rulebook.rulebook.md>` — <what it governs>
```

## Writing guidelines

1. **Forward-looking.** An ADR describes the architecture as it is or will be, not the migration work that got it there.

2. **No file paths.** Do not write `src/<module>/<file>.ts`. Use class names, layer names, and illustrative code blocks instead. File paths rot; architectural concepts don't.

3. **Code examples only when necessary.** Use generic class names in illustrative blocks.

4. **Number decisions.** Other documents reference decisions as "per ADR §D1" or "see layering.adr.md D3".

5. **Status is required.** PROPOSED means under discussion. ACCEPTED means in effect. SUPERSEDED means replaced by a newer ADR (link it).

6. **Date is required.** So readers know how old the decision is.

## When to write an ADR vs other doc types

| Situation | Document type |
|-----------|---------------|
| Locking a specific architectural decision | ADR |
| Normative rules that downstream docs cite | Rulebook |
| Feature design for implementation | Spec |
| Task breakdown for execution | Task list |
| Quick reference for agents | Rule file |
