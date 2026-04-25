---
paths:
  - "src/backend/**/*.ts"
  - "src/backend-for-frontend/**/*.ts"
---

# Nest.js Testing

> Extends [common/testing.md](../common/testing.md) and [typescript/testing.md](../typescript/testing.md). Where this file conflicts with either, this file wins for Nest code.

## Framework

Vitest, not Jest. Use `@nestjs/testing` for module setup. Vitest is faster and has better ESM support.

## What to Test (and What Not To)

The `common/testing.md` 80% coverage target and strict TDD workflow are softened for Nest code. Chasing 80% coverage means writing tests for module shells, DTO definitions, and decorator metadata that don't catch real bugs.

**Tests are required for:**
- Repositories — every named method, against an in-memory database with the real schema
- Services with logic — anything that orchestrates, branches, or transforms
- Custom transports — pattern dispatch, lifecycle, error propagation
- Anything with invariants the spec calls out
- Anything listed in a task's acceptance criteria

**Tests are optional for:**
- Module shells (`@Module({...})` declarations with no logic)
- DTO type definitions
- Decorator metadata
- Trivial pass-through controllers
- Generated code

There is no fixed coverage percentage. The standard is: every behavior the spec or task acceptance criteria names has a test that would fail if the behavior broke.

## Test Structure

Co-locate tests with the code they test. `order.repository.ts` and `order.repository.test.ts` in the same directory.

```typescript
describe('OrderRepository', () => {
  let repo: OrderRepository;
  let db: DbConnection;

  beforeEach(() => {
    db = new Database(':memory:');
    db.exec(readFileSync('migrations/001_orders.sql', 'utf-8'));
    repo = new OrderRepository(db);
  });

  afterEach(() => db.close());

  it('byCustomer returns empty array when no orders exist', async () => {
    expect(await repo.byCustomer('customer-123')).toEqual([]);
  });

  it('ship updates status and timestamp', async () => {
    const id = await repo.insert({ customerId: 'customer-123', total: 100, status: 'pending' });
    await repo.ship(id);
    const order = await repo.byId(id);
    expect(order?.status).toBe('shipped');
  });
});
```

## Mocking

Use `@nestjs/testing`'s `Test.createTestingModule()` for service tests with multiple injected dependencies. Override providers with mocks rather than constructing classes manually.

```typescript
const module = await Test.createTestingModule({
  providers: [
    CheckoutService,
    { provide: OrderRepository, useValue: createMock<OrderRepository>() },
    { provide: InventoryRepository, useValue: createMock<InventoryRepository>() },
    { provide: DB_CONNECTION, useValue: new Database(':memory:') },
  ],
}).compile();

const service = module.get(CheckoutService);
```

## Database Tests

Use `:memory:` SQLite for repository tests. Run the actual migration SQL files to set up the schema — don't hand-write CREATE TABLE statements in tests, they'll drift from production.

## Soften the TDD Rule

The strict RED-GREEN-REFACTOR mandate from `common/testing.md` applies when:
- Adding logic to a service or repository
- Implementing an acceptance criterion from a task

It does NOT apply when:
- Scaffolding a module or controller shell
- Adding a DTO or type
- Wiring providers in a module

Practically: write tests when you're about to write logic. Don't write tests for boilerplate.

---

Adapt paths in the frontmatter to match your project structure.
