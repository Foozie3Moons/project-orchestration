---
paths:
  - "src/backend/**/*.ts"
  - "src/backend-for-frontend/**/*.ts"
---

# NestJS Security

> Extends `common/security.md` and `typescript/security.md`. Where this file conflicts with either, this file wins for Nest code.

## Mandatory Security Checks (Backend)

In addition to the universal checks in `common/security.md`, verify before any commit touching Nest code:

- [ ] SQL injection prevention — all queries use parameterized statements. See `nestjs/patterns.md` §Prepared Statements for the required pattern.
- [ ] CSRF protection enabled on any stateful HTTP endpoints
- [ ] Authentication/authorization verified — protected routes use guards; no endpoint is accidentally open
- [ ] Rate limiting on all endpoints exposed to external callers

---

Extends `common/security.md` and `typescript/security.md`. Adapt paths in the frontmatter to match your project structure.
