# Memory Patterns Rulebook

How to structure the Claude Code memory system for effective cross-session recall.

## §1 Memory location

```
~/.claude/projects/<project-slug>/memory/
├── MEMORY.md           # Index file (always loaded)
├── user_*.md           # User profile memories
├── feedback_*.md       # Guidance/corrections
├── project_*.md        # Ongoing work context
└── reference_*.md      # External system pointers
```

The `<project-slug>` is derived from the project path: `/home/user/src/myapp` → `-home-user-src-myapp`.

## §2 Memory types

### §2.1 User memories (`user_*.md`)

**Purpose:** Who the user is, their role, expertise, preferences.

**When to save:**
- Learning about user's role or responsibilities
- Discovering expertise levels (expert in X, new to Y)
- Understanding how to tailor explanations

**Example:**
```markdown
---
name: user_expertise
description: User's technical background and expertise areas
type: user
---

Staff engineer, deep backend experience (10 years), new to React.
Frame frontend explanations in terms of backend analogues.
```

### §2.2 Feedback memories (`feedback_*.md`)

**Purpose:** Corrections and confirmations of approach.

**When to save:**
- User corrects your approach ("don't do X")
- User confirms a non-obvious approach worked ("yes, exactly")
- Learning what to repeat or avoid

**Structure:**
```markdown
---
name: feedback_testing
description: User's testing preferences
type: feedback
---

Integration tests must hit a real database, not mocks.

**Why:** Prior incident where mock/prod divergence masked a broken migration.

**How to apply:** For any test touching database code, use in-memory SQLite with real schema.
```

### §2.3 Project memories (`project_*.md`)

**Purpose:** Ongoing work, goals, deadlines, who's doing what.

**When to save:**
- Learning about current initiatives
- Understanding deadlines or constraints
- Tracking who owns what

**Structure:**
```markdown
---
name: project_auth_rewrite
description: Auth middleware rewrite context
type: project
---

Auth middleware rewrite driven by legal/compliance requirements around session token storage.

**Why:** Legal flagged current implementation, not tech-debt cleanup.

**How to apply:** Scope decisions should favor compliance over ergonomics.
```

### §2.4 Reference memories (`reference_*.md`)

**Purpose:** Pointers to external systems.

**When to save:**
- Learning where information lives (Linear project, Slack channel, wiki page)
- Understanding where to look for specific types of info

**Example:**
```markdown
---
name: reference_bugs
description: Where to find bug tracking
type: reference
---

Pipeline bugs tracked in Linear project "INGEST".
API bugs tracked in Linear project "API".
```

## §3 MEMORY.md index

The index file is always loaded. Keep it concise (<200 lines after truncation).

**Format:**
```markdown
- [User expertise](user_expertise.md) — backend expert, React beginner
- [Testing approach](feedback_testing.md) — real DB, no mocks
- [Auth rewrite](project_auth_rewrite.md) — compliance-driven
```

One line per memory, <150 characters.

## §4 What NOT to save

- Code patterns derivable from the codebase
- Git history (`git log` is authoritative)
- Debugging solutions (the fix is in the code)
- Anything in CLAUDE.md or rule files
- Ephemeral task details

If the user asks to save something that belongs elsewhere, ask what's surprising or non-obvious about it — that part is worth keeping.

## §5 Memory lifecycle

### §5.1 Creating memories

1. Write the memory file with frontmatter
2. Add a one-line entry to MEMORY.md
3. Organize semantically by topic, not chronologically

### §5.2 Updating memories

- Check for existing memory before creating new
- Update in place if the topic exists
- Keep name/description/type in sync with content

### §5.3 Removing memories

- Remove when stale or proven wrong
- Remove the MEMORY.md entry too
- Don't leave orphaned index entries

## §6 Memory vs other persistence

| Need | Use |
|------|-----|
| Remember across sessions | Memory |
| Track current task progress | Tasks (TaskCreate/TaskUpdate) |
| Plan implementation approach | Plan (EnterPlanMode) |
| Document permanent decisions | ADR |
| Quick agent reference | Rule file |

Memory is for information useful in FUTURE sessions. Current-session state uses other tools.

## §7 Verification before acting

Memories can become stale. Before acting on a memory:

- If it names a file path: check the file exists
- If it names a function: grep for it
- If it describes repo state: verify with current reads

"The memory says X exists" ≠ "X exists now."
