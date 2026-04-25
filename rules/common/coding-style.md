# Coding Style

## Immutability

Create new objects and return them from public APIs. Do not mutate values that have escaped the function that created them.

```
// Pseudocode
WRONG:  modify(original, field, value) → changes a value the caller still holds
CORRECT: update(original, field, value) → returns a new copy with the change
```

Rationale: immutability across module boundaries prevents hidden side effects and makes debugging easier.

**Scope:** this rule applies to values that cross function or module boundaries. Local mutation of an object inside the function that created it is fine. See `nestjs/patterns.md` for the backend-specific scope.

## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large modules
- Organize by feature/domain, not by type

## Error Handling

Handle errors comprehensively:
- Handle errors explicitly at every level
- Provide user-friendly error messages in UI-facing code
- Log detailed error context on the server side
- Never silently swallow errors

## Input Validation

Validate at system boundaries:
- Validate all user input before processing
- Use schema-based validation where available
- Fail fast with clear error messages
- Never trust external data (API responses, user input, file content)

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No hardcoded values (use constants or config)
- [ ] No mutation of values that escape their creating function

---

Extended by `typescript/coding-style.md` for TypeScript/JavaScript files, and further by `nestjs/coding-style.md` for Nest backend code. Where those files conflict with this file, the more specific file wins.
