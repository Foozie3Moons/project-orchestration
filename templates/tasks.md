# Task List Template

Task lists are the decomposer's output and the orchestrator's input. They break a spec into parallelizable units of work with exclusive file ownership.

## Filename

`docs/tasks/<feature>.md` — matches the feature name of the source spec in `docs/specs/<feature>.md`.

## Structure

```markdown
# <Feature Name> — Tasks

**Source spec:** `docs/specs/<feature>.md`
**Generated:** YYYY-MM-DD

## Overview

| Phase | Tasks | Parallelizable | Agents |
|-------|-------|----------------|--------|
| 1     | T1-T3 | Yes            | infra-engineer, domain-engineer |
| 2     | T4-T5 | Yes            | domain-engineer, frontend-engineer |
| 3     | T6    | No             | frontend-engineer |

## Phase 1: <Phase description>

### T1: <Task title>

**Agent:** `<agent-name>`
**Depends on:** (none) | T<n>
**Estimated size:** S / M / L

**Owns:**
- `path/to/dir/` — <what this task creates or modifies>
- `path/to/file.ts`

**Does not own:**
- `path/other/` — (owned by T<n>)

**Description:**
<What this task accomplishes. Include enough context that the assigned agent can execute without reading other tasks.>

**Acceptance criteria:**
- [ ] `path/to/file.ts` exists
- [ ] Build passes (`npm run build`)
- [ ] Test `<test-name>` passes
- [ ] <Specific behavior is verified>

---

### T2: <Task title>

(Continue for each task in this phase)

---

## Phase 2: <Phase description>

### T4: <Task title>

**Depends on:** T1, T2

(Continue pattern)

---

## Verification Checklist

After all tasks complete:
- [ ] Full build passes
- [ ] All tests pass
- [ ] Feature works end-to-end (manual verification or E2E test)
- [ ] No regressions in existing functionality
```

## Writing guidelines

1. **File ownership is exclusive.** No two tasks touch the same file. This is non-negotiable; it's the only thing that makes parallel execution actually parallel.

2. **Tasks are sized for one focused session.** 200-500 lines of code, 3-8 files, single bounded context. Split anything bigger.

3. **Acceptance criteria are verifiable checkboxes.** "Build passes," "test X exists and passes," "endpoint Y returns shape Z." Never "works correctly," never "looks good."

4. **Dependencies are explicit and minimal.** A task depends on another only when it literally cannot start without the other's output.

5. **Each task has one assigned agent.** The assignment goes in the task header for orchestrator dispatch.

6. **Tasks are self-contained.** Repeat key types and acceptance criteria rather than cross-referencing. Implementation agents work with focused context windows.

7. **No placeholders.** Every task contains actual content, not "TBD" or "similar to Task N".

## Phases

Group tasks into phases based on dependencies:
- **Phase 1:** Tasks with no dependencies (can all run in parallel)
- **Phase 2:** Tasks that depend on Phase 1 outputs
- **Phase N:** Continue until all tasks are assigned

Within a phase, all tasks can run in parallel (assuming different agents or non-overlapping file ownership).

## Task sizing

| Size | Lines of code | Files | Duration |
|------|---------------|-------|----------|
| S    | <200          | 1-3   | <30 min  |
| M    | 200-500       | 3-8   | 30-90 min |
| L    | 500+          | 8+    | >90 min (consider splitting) |

If a task is L, split it by subdirectory first, by layer second, by feature slice third.
