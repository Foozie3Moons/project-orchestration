# Spec Template

Feature specs describe the target state of a feature. They are the architect's output and the decomposer's input. Specs are consumed once and can go stale after the work lands — they are not long-lived reference material.

## Filename

`docs/specs/<feature>.md` — one file per feature.

## Structure

```markdown
# <Feature Name>

## Problem

<What pain point does this solve?>
<Who experiences it?>
<What does success look like?>

## Current State

<What exists today?>
<What code, files, or behavior is relevant?>
<Include a brief directory listing or component diagram if helpful.>

## Target State

<What should exist after this work?>
<How does the system behave differently?>
<What new files, modules, or components are created?>

## Constraints

<What must be preserved?>
<What stack/technology decisions are locked?>
<What backwards compatibility is required?>
<What is explicitly out of scope?>

## Decisions

### D1: <Decision title>

<What we decided and why. These are the load-bearing choices that constrain implementation.>

### D2: <Decision title>

<Continue for each decision.>

## API / Data Shapes

<If the feature exposes APIs, define them here.>
<If new data structures are needed, define them here.>

```typescript
// Example type definitions
interface NewEntity {
  id: string;
  // ...
}
```

## UI Changes (if applicable)

<What screens or components change?>
<Wire up to backend features — every backend capability needs a frontend surface.>

## Open Questions

<List any unresolved items that need answers before decomposition.>
<If this section is non-empty, the spec is not ready for decomposition.>

## Next Step

Hand this spec to the decomposer to produce a task list.
```

## Writing guidelines

1. **Tables over prose.** Use tables for comparisons, state transitions, field mappings.

2. **ASCII diagrams over descriptions.** A box-and-arrow diagram beats three paragraphs.

3. **Types as documentation.** TypeScript interfaces document shape better than prose.

4. **Diff-oriented.** Current state vs target state makes the delta clear.

5. **No redundancy.** Don't repeat the same information in multiple sections.

6. **Trace backend to frontend.** If the feature has config, status, or output that a user sees or controls, the spec must include the UI component or API response change.

7. **Resolve before decomposing.** If Open Questions is non-empty, the spec isn't ready. Go back to discovery.

## When the spec is ready

The spec is ready for decomposition when:
- Problem statement is clear
- Current state is documented
- Target state is specific enough that two engineers would build the same thing
- Load-bearing decisions are made (not deferred to implementation)
- Open questions section is empty
