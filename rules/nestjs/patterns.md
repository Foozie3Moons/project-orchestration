---
paths:
  - "src/backend/**/*.ts"
  - "src/backend-for-frontend/**/*.ts"
---

# Nest.js Patterns

> Extends [common/patterns.md](../common/patterns.md) and [typescript/patterns.md](../typescript/patterns.md). Where this file conflicts with either, this file wins for Nest code.

Layer placement and cross-module rules: see `./layering.md`.

## Repository Pattern

Repositories use **named domain methods**, not generic CRUD. The generic `Repository<T>` interface from `typescript/patterns.md` is explicitly NOT used in Nest code.

```typescript
// CORRECT - named domain methods
@Injectable()
export class OrderRepository {
  private readonly findByCustomer: Statement<[string], OrderRow>;
  private readonly insertOrder: Statement<[OrderInsert]>;
  private readonly markShipped: Statement<[number, number]>;

  constructor(@Inject(DB_CONNECTION) private readonly db: DbConnection) {
    this.findByCustomer = db.prepare('SELECT * FROM orders WHERE customer_id = ?');
    this.insertOrder = db.prepare('INSERT INTO orders (customer_id, total, status) VALUES (@customer_id, @total, @status)');
    this.markShipped = db.prepare('UPDATE orders SET status = ?, shipped_at = ? WHERE id = ?');
  }

  async byCustomer(customerId: string): Promise<Order[]> {
    const rows = this.findByCustomer.all(customerId);
    return rows.map(this.toEntity);
  }

  async ship(orderId: number): Promise<void> {
    this.markShipped.run('shipped', Date.now(), orderId);
  }
}

// WRONG - generic CRUD
export class OrderRepository implements Repository<Order> {
  findAll(): Promise<Order[]> { ... }
  findById(id: string): Promise<Order> { ... }
  create(data: CreateDto): Promise<Order> { ... }
}
```

Why: generic CRUD leaks "this is a database table" into every consumer. Named methods document intent at the call site.

## Prepared Statements

Statements are constructed once in the repository constructor and stored as `private readonly` fields. Never construct prepared statements inline in methods.

```typescript
// CORRECT
constructor(@Inject(DB_CONNECTION) db: DbConnection) {
  this.findActiveSessions = db.prepare('SELECT * FROM sessions WHERE archived_at IS NULL');
  this.archiveSession = db.prepare('UPDATE sessions SET archived_at = ? WHERE id = ?');
}

// WRONG
async getActive() {
  return this.db.prepare('SELECT * FROM sessions WHERE archived_at IS NULL').all();
}
```

## No ORM

Use your database driver directly. Never introduce TypeORM, Prisma, MikroORM, Drizzle, or any other ORM. The repository pattern above is the abstraction.

## Service Layer

Services orchestrate repositories. Repositories never call other repositories. If cross-aggregate consistency is needed, the service opens a transaction:

```typescript
@Injectable()
export class CheckoutService {
  constructor(
    @Inject(DB_CONNECTION) private readonly db: DbConnection,
    private readonly orders: OrderRepository,
    private readonly inventory: InventoryRepository,
  ) {}

  async checkout(input: CheckoutInput): Promise<void> {
    const tx = this.db.transaction((input: CheckoutInput) => {
      const orderId = this.orders.insert(input);
      for (const item of input.items) {
        this.inventory.decrement(item.productId, item.quantity);
      }
      return orderId;
    });
    tx(input);
  }
}
```

## API Response Format

Nest-idiomatic. Return raw data on success. Throw `HttpException` subclasses on error. Do NOT use the `{success, data, error}` envelope from `common/patterns.md` or `typescript/patterns.md`.

```typescript
// CORRECT
@Get(':id')
async getOne(@Param('id') id: string): Promise<Session> {
  const session = await this.sessions.findById(id);
  if (!session) throw new NotFoundException(`Session ${id} not found`);
  return session;
}

// WRONG
@Get(':id')
async getOne(@Param('id') id: string): Promise<ApiResponse<Session>> {
  const session = await this.sessions.findById(id);
  if (!session) return { success: false, error: 'Not found' };
  return { success: true, data: session };
}
```

## DTOs and Validation

Use Zod schemas for request body and response validation. Define DTOs at the controller boundary. Never leak internal entity types directly to the wire.

```typescript
const CreateSessionDto = z.object({
  chatId: z.number().int(),
  userId: z.number().int(),
  skillId: z.string(),
});
type CreateSessionDto = z.infer<typeof CreateSessionDto>;

@Post()
async create(@Body(new ZodPipe(CreateSessionDto)) body: CreateSessionDto) {
  return this.service.createSession(body);
}
```

## Lifecycle Hooks

Use Nest lifecycle interfaces explicitly:

- `OnModuleInit` — for setup that needs other providers already constructed
- `OnApplicationBootstrap` — for setup that needs the entire app ready
- `OnApplicationShutdown` — for cleanup

```typescript
@Injectable()
export class SkillRegistry implements OnApplicationBootstrap {
  onApplicationBootstrap() {
    // scan providers via DiscoveryService
  }
}
```

## Immutability Scope (Backend Override)

The "ALWAYS create new objects, NEVER mutate" rule from `common/coding-style.md` applies to **public API surfaces** (return values from services, payloads sent to other modules). It does NOT apply to:

- Repository internals (prepared statement params, row mapping)
- Nest's request lifecycle internals
- Builder patterns inside a single function scope
- Local mutation of objects that haven't escaped the function

---

Adapt paths in the frontmatter to match your project structure.
