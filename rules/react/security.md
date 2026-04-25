---
paths:
  - "src/frontend/**"
---

# React Security

> Extends `common/security.md` and `typescript/security.md`.

## Mandatory Security Checks (Frontend)

In addition to the universal checks in `common/security.md`, verify before any commit touching React code:

- [ ] XSS prevention — React escapes JSX by default. Never use `dangerouslySetInnerHTML` without explicit sanitization of the HTML string before it is passed.

For secret handling in frontend code (API keys, tokens embedded in the bundle), see `typescript/security.md`.

---

Extends `common/security.md` and `typescript/security.md`. Adapt paths in the frontmatter to match your project structure.
