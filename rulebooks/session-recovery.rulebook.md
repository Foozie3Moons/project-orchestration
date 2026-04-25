# Session Recovery Rulebook

How to recover context from previous Claude Code sessions.

## §1 Available sources

### §1.1 Global history

`~/.claude/history.jsonl` — every prompt ever typed, with project path and timestamp.

**Use for:** "What did I say about X?", "When did I last work on Y?"

**Format:**
```json
{"timestamp":"2026-04-24T10:30:00Z","project":"/home/user/src/myapp","prompt":"fix the auth bug"}
```

### §1.2 Session transcripts

`~/.claude/projects/<project-slug>/<session-id>.jsonl` — full conversation (user + assistant + tool calls).

**Use for:** "What did we decide?", "What was the conclusion?"

**Format:** JSONL with message objects including role, content, tool calls, and tool results.

### §1.3 Project memory

`~/.claude/projects/<project-slug>/memory/*.md` — distilled memories.

**Use for:** "What do we know about X?", "What were the user's preferences?"

### §1.4 Dispatch log

`.claude/dispatch-log.jsonl` — record of agent dispatches.

**Use for:** "What agents ran?", "What task was being worked on?"

**Format:**
```json
{"ts":"...","event":"start","tool_use_id":"...","agent":"infra-engineer","task":"T-1"}
{"ts":"...","event":"end","tool_use_id":"...","status":"returned","duration_s":42}
```

### §1.5 Project documents

`.claude/agents/`, `docs/specs/`, `docs/tasks/`, `docs/architecture/`

**Use for:** "What does the spec say?", "What was the plan?"

## §2 Search strategy

Order by cost (cheapest first):

1. **MEMORY.md index** — already loaded, check first
2. **Memory files** — grep for keywords
3. **Dispatch log** — if asking about recent work
4. **Global history** — for "what did I say" questions
5. **Project documents** — for "what did we decide" questions
6. **Session transcripts** — last resort, large files

Don't dump entire session transcripts. Quote precisely.

## §3 history.sh tool

If `.claude/scripts/history.sh` exists, use it:

```bash
# List recent sessions
bash .claude/scripts/history.sh sessions list --since 7

# Search across sessions
bash .claude/scripts/history.sh sessions grep "auth bug"

# Show specific session
bash .claude/scripts/history.sh sessions show <session-id> --last 50

# Query dispatch log
bash .claude/scripts/history.sh dispatches --task T-1
bash .claude/scripts/history.sh dispatches --agent infra-engineer --since 3

# Search memory
bash .claude/scripts/history.sh memory grep "testing"
```

Prefer this over ad-hoc `jq`/`grep` commands.

## §4 Citation format

When surfacing recovered context, cite precisely:

```markdown
Found in session abc123 (2026-04-20 14:30):
> "let's use SQLite instead of Postgres for simplicity"

This led to the decision in `docs/architecture/database.adr.md` D1.
```

Include:
- Session ID or file path
- Timestamp
- Quoted user phrasing
- Link to any resulting document

## §5 When nothing is found

Say so directly:

```markdown
I searched:
- Memory files (no matches for "kubernetes")
- Last 7 days of sessions (no mentions)
- Dispatch log (no related tasks)

This topic doesn't appear in the project history. Is it from a different project, or before the history window?
```

Do NOT fabricate decisions that weren't made.

## §6 Ambiguous questions

If the user's question is ambiguous, ask ONE clarifying question before searching:

- "Auth bug" — which one? The login flow or the token refresh?
- "What we decided" — about which feature?
- "Last week" — the work on X or Y?

Don't search blindly across everything.

## §7 Cross-session context recovery

When recovering context for continuing work:

1. Check dispatch log for last tasks worked on
2. Read the relevant task list in `docs/tasks/`
3. Check which tasks are complete (git log, file existence)
4. Read any relevant specs in `docs/specs/`
5. Summarize: "Last session worked on T3-T5. T3 and T4 are complete. T5 was in progress."

## §8 Privacy considerations

Session history contains everything the user typed. When summarizing:

- Don't expose sensitive content unnecessarily
- Quote the minimum needed to answer the question
- If asked to share history, confirm with user first
