# Testing Requirements

## Minimum Test Coverage: 80%

Test Types (ALL required):
1. **Unit Tests** - Individual functions, utilities, components
2. **Integration Tests** - API endpoints, database operations
3. **E2E Tests** - Critical user flows (framework chosen per language)

## Test-Driven Development

MANDATORY workflow:
1. Write test first (RED)
2. Run test - it should FAIL
3. Write minimal implementation (GREEN)
4. Run test - it should PASS
5. Refactor (IMPROVE)
6. Verify coverage (80%+)

## Troubleshooting Test Failures

1. Check test isolation
2. Verify mocks are correct
3. Fix implementation, not tests (unless tests are wrong)

---

Extended by `typescript/testing.md` for TypeScript/JavaScript files, and further by `nestjs/testing.md` for Nest backend code. The 80% coverage target in this file is softened by `nestjs/testing.md` §"What to Test (and What Not To)" for Nest code. Where those files conflict with this file, the more specific file wins.
