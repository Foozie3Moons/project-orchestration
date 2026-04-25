# Agent Definition Template

Agent definitions tell Claude Code how to behave when dispatched as a specific agent type. They are created by the agent-creator from an architecture spec.

## Filename

`.claude/agents/<name>.md` — name is typically `<context>-engineer` for implementation agents.

## Structure

```markdown
---
name: <agent-id>
description: <one-line scope summary for orchestrator dispatch>
tools: Read, Write, Edit, Bash, Glob, Grep
model: claude-sonnet-4-5 | claude-opus-4-5
---

<Opening paragraph: role, what you own, pointer to spec or rulebook>

# Your scope

You own these modules in all their layers:

- `path/to/module/` — <brief description>

You do NOT own:

- `path/to/other/` — (<other-agent>)
- Shared contracts unless explicitly assigned

## Layer discipline

<If project has a layering model, point at the rulebook.>
<State that ownership is vertical — agent owns module across all layers.>

# Working rules

1. <Stack-specific rule — what to do, why, when to deviate>
2. <Architectural invariant — what must always be true>
3. <Spec decision — specific choice that constrains implementation>

# Code style

<Pointer to project's coding style rules>
<Any agent-specific style notes>

# Working loop

1. Read the task brief
2. Verify the task is in your scope
3. Implement the changes
4. Run build and tests
5. Verify acceptance criteria
6. Output a summary of what changed

# Pushback

Push back when:
- Task violates the spec
- Task crosses ownership boundary
- Acceptance criterion is not verifiable
- Stack constraint makes approach infeasible

When you push back, state the problem, propose a fix, and stop.

# Things you do not do

- You do not <things outside scope>.
- You do not <things that belong to other agents>.
- You do not commit. The user handles git.
```

## Agent patterns

**Horizontal (layer-based):** Owns a layer across the codebase. Examples: `infra-engineer`, `domain-engineer`, `api-engineer`. Use when layers are independent.

**Vertical (feature-based):** Owns a feature across the full stack. Examples: `chat-engineer`, `auth-engineer`, `billing-engineer`. Use when a feature has tight coupling between frontend and backend.

Most projects use a mix. The agent-creator decides based on your spec's bounded contexts.

## Frontmatter fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Agent identifier, used in `subagent_type` |
| `description` | Yes | One-line summary for orchestrator dispatch decisions |
| `tools` | Yes | Tools the agent can use |
| `model` | No | Model override (sonnet for impl, opus for prompts/architecture) |

## Writing guidelines

1. **Scope is exclusive.** No two agents own the same file. If overlap exists, the spec is wrong.

2. **Working rules are stack-specific.** Derive from the spec's tech stack section and architectural invariants.

3. **Pushback triggers are explicit.** Tell the agent exactly when to stop and report rather than proceed.

4. **"Things you do not do" is a boundary.** List what belongs to other agents, what's out of scope, what's forbidden.

5. **No generic rules.** Everything in the agent definition should be specific to this agent's context. Generic rules go in rule files.

## Model selection

- **claude-sonnet-4-5** — default for implementation work. Fast, reliable, good at mechanical tasks.
- **claude-opus-4-5** — for prompt-sensitive work (skill authoring, system prompt design) or complex architectural reasoning.

Assign model based on cognitive load of the typical task, not importance of the module.

## Coordination rules

When two agents share a boundary, both need coordination rules:

**Consumer/provider:**
- Provider's rule: "Changes to <Interface> require notifying <Consumer>"
- Consumer's rule: "If <Provider>'s interface doesn't expose what you need, stop and report"

**Shared contract:**
- Both rules: "Changes to <Contract> require cross-agent sign-off"

## Invariant patterns

Some agents exist to protect a specific invariant. Encode explicitly:

```markdown
# The invariant

There is one invariant you exist to protect: **<statement>**.

Operationally:
- <what this means for imports>
- <what this means for dependencies>
- <what this means for error handling>
```
