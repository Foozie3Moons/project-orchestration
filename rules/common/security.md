# Security Guidelines

## Mandatory Security Checks

Before ANY commit:
- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user inputs validated
- [ ] Error messages don't leak sensitive data

## Secret Management

- NEVER hardcode secrets in source code
- ALWAYS use environment variables or a secret manager
- Validate that required secrets are present at startup
- Rotate any secrets that may have been exposed

## Security Response Protocol

If security issue found:
1. STOP immediately
2. Fix CRITICAL issues before continuing
3. Rotate any exposed secrets
4. Review entire codebase for similar issues

---

Extended by `typescript/security.md` for TypeScript/JavaScript files. Backend-specific security checks (SQL injection, CSRF, auth/authz, rate limiting) live in `nestjs/security.md`. Frontend-specific checks (XSS) live in `react/security.md`. Where those files conflict with this file, the more specific file wins.
