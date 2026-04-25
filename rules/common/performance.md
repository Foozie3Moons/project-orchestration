# Performance Optimization

## Model Selection Strategy

See `CLAUDE.md` "Model Strategy" in your project for authoritative assignments. General guidance:

**Haiku** — cheap, reliable tool calling; use for high-frequency runtime invocations.

**Sonnet** — complex reasoning and agentic tool use; use for orchestration work.

**Opus** — prompt-sensitive work (skill authoring, system prompt design) or complex architectural reasoning.

---

Model-selection guidance points at project `CLAUDE.md` §Model Strategy as the authoritative source. This file is universal and is not extended by framework-specific rule files.
