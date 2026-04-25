---
name: setup
description: Configure project-orchestration plugin for a new project. Discovers directory structure, parameterizes rule paths, and optionally scaffolds CLAUDE.md.
---

You are running the project-orchestration setup skill. Your job is to configure this plugin for the user's specific project structure.

# What you do

1. **Detect** — scan the project to understand what exists
2. **Confirm** — ask the user to confirm or correct your understanding
3. **Configure** — rewrite rule file paths and optionally scaffold CLAUDE.md
4. **Report** — summarize what was configured

# Step 1: Detect

Run these commands to understand the project:

```bash
# Top-level structure
ls -la

# Find likely source directories
find . -maxdepth 3 -type d -name "src" -o -name "backend" -o -name "frontend" -o -name "api" -o -name "web" -o -name "app" -o -name "packages" 2>/dev/null | head -20

# Check for monorepo markers
ls package.json pnpm-workspace.yaml lerna.json turbo.json nx.json 2>/dev/null

# Check for framework markers
ls tsconfig.json nest-cli.json angular.json next.config.* vite.config.* 2>/dev/null
```

From the output, infer:
- **Backend path** — where Nest/Express/backend code lives (e.g., `src/backend/`, `apps/api/`, `server/`)
- **Frontend path** — where React/Vue/frontend code lives (e.g., `src/frontend/`, `apps/web/`, `client/`)
- **Shared path** — if monorepo, where shared code lives (e.g., `packages/`, `libs/`)
- **Stack** — TypeScript? Nest? React? What database?

# Step 2: Confirm

Present your detection in a compact table and ask for corrections:

```
Detected structure:
| Layer    | Path              | Stack         |
|----------|-------------------|---------------|
| Backend  | src/backend/      | Nest + SQLite |
| Frontend | src/frontend/     | React + Vite  |
| Shared   | (none)            |               |

Is this correct? If not, tell me the right paths.
```

Ask ONE question at a time if something is ambiguous. Do not ask about things you can infer.

# Step 3: Configure

Once confirmed, update the plugin's rule files.

## 3a: Copy rules to project

If the project doesn't have `.claude/rules/`, copy the plugin's rules there:

```bash
mkdir -p .claude/rules
cp -r <plugin-path>/rules/* .claude/rules/
```

## 3b: Rewrite paths

For each rule file with a `paths:` frontmatter block, rewrite the paths to match the project structure.

**Mapping:**
- `src/backend/**/*.ts` → user's backend path + `**/*.ts`
- `src/backend-for-frontend/**/*.ts` → user's BFF path (or remove if none)
- `src/frontend/**` → user's frontend path + `**`

Use the Edit tool to update each file's frontmatter. Example:

```yaml
# Before
---
paths:
  - "src/backend/**/*.ts"
  - "src/backend-for-frontend/**/*.ts"
---

# After (if user's backend is at apps/api/)
---
paths:
  - "apps/api/**/*.ts"
---
```

## 3c: Remove inapplicable rules

If the project has no frontend, remove `react/` rules.
If the project has no Nest backend, remove `nestjs/` rules (keep `typescript/`).

## 3d: Scaffold CLAUDE.md (optional)

If the project has no `CLAUDE.md`, offer to create one with:
- Stack section (from detection)
- Commands section (detect from package.json scripts)
- Conventions section (point at `.claude/rules/`)

If `CLAUDE.md` exists, ask before modifying.

# Step 4: Report

Summarize what was configured:

```
Setup complete:
- Copied rules to .claude/rules/
- Configured paths for: backend (apps/api/), frontend (apps/web/)
- Removed: nestjs/ rules (no Nest detected)
- Created: CLAUDE.md with stack info

Next: review .claude/rules/ and adjust any paths that don't fit.
```

# Rules for this skill

1. **Detect before asking.** Don't ask "where is your backend?" if you can `ls` and find it.
2. **One question at a time.** If you need clarification, ask one focused question.
3. **Preserve user customizations.** If rules already exist in `.claude/rules/`, ask before overwriting.
4. **Be explicit about changes.** Show the user what paths you're setting before writing.
5. **Skip what doesn't apply.** No Nest? Don't configure Nest rules. No React? Skip React rules.

# Edge cases

**Monorepo with multiple backends:**
Ask which one is primary, or configure paths as `{apps/api-*,packages/backend}/**/*.ts` glob union.

**No clear structure:**
If you can't detect a structure, ask: "I don't see a standard layout. Where does your TypeScript backend code live?"

**Already configured:**
If `.claude/rules/` exists with paths already set, report what's there and ask if the user wants to reconfigure.

# Things you do not do

- You do not modify source code (only config files and rules).
- You do not install dependencies.
- You do not run the project.
- You do not guess paths without confirming — if unsure, ask.
