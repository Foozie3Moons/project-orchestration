---
paths:
  - "src/backend/**/*.ts"
  - "src/backend-for-frontend/**/*.ts"
---

# Nest.js Coding Style

> Extends [common/coding-style.md](../common/coding-style.md) and [typescript/coding-style.md](../typescript/coding-style.md). Where this file conflicts with either, this file wins for Nest code.

Layer placement and cross-module rules: see `./layering.md`.

## Dependency Injection

Constructor injection only. No property injection. No service locator pattern.

```typescript
// CORRECT
@Injectable()
export class StapleService {
  constructor(
    private readonly staples: StapleRepository,
    private readonly logger: Logger,
  ) {}
}

// WRONG
@Injectable()
export class StapleService {
  @Inject(StapleRepository) private staples: StapleRepository;
}
```

Dependencies are typed by class or by injection token (Symbol). String tokens only when interfacing with Nest built-ins that require them.

```typescript
// Injection tokens
export const DB_CONNECTION = Symbol('DB_CONNECTION');
export const PII_SANITIZER = Symbol('PII_SANITIZER');

// Usage
constructor(
  @Inject(DB_CONNECTION) private readonly db: DbConnection,
  @Inject(PII_SANITIZER) private readonly sanitizer: PiiSanitizer,
) {}
```

## Module Organization

One bounded context per module. The module file sits at the module root — not inside a layer subdirectory.

```
src/backend/<module>/
├── <module>.module.ts       # Nest module declaration — lives at root, not in a layer
├── api/                     # @Controller endpoints, @MessagePattern handlers, DTOs
├── use-case/                # OPTIONAL — composite workflows spanning multiple application services
├── application/             # Single-transaction orchestration; one service per business operation
├── data-access/             # Repositories (database) and outbound gateways (HTTP/SDK clients)
└── domain/                  # Entities, value objects, pure business rules — no I/O, no Nest imports
```

Layers may be omitted if the module does not need them. Modules export only application services and domain types that other contexts genuinely need. Repositories, gateways, and use-case classes stay private.

## No Barrel Files

No `index.ts` re-export files unless a task explicitly requires one. Barrel files cause circular import issues with Nest's module system and obscure where things actually live. Import from the source file directly.

```typescript
// CORRECT
import { StapleRepository } from './staples/staple.repository';

// WRONG
import { StapleRepository } from './staples';
```

Why tempting: barrel files are the dominant TS/JS convention.

Failure mode: Nest's module resolution resolves barrel re-exports at class-declaration time; circular barrel references produce cryptic `undefined` providers at boot.

## Decorators

Decorators belong above the symbol they apply to, one per line. Order: framework decorators (@Injectable, @Controller) first, then routing/metadata decorators (@Get, @MessagePattern), then parameter decorators inline.

```typescript
@Controller('staples')
export class StaplesController {
  @Get(':id')
  async getOne(@Param('id') id: string): Promise<Staple> {
    return this.service.findById(id);
  }
}
```

## File Length

400 lines is the soft target, 600 is the cap. If a service is approaching 600, split by responsibility.

## Line Length

100 characters. Constructor parameter lists often exceed this — break onto multiple lines with one parameter per line.

## Logger

Inject Nest's `Logger` from `@nestjs/common`. Never `console.log`.

```typescript
import { Logger } from '@nestjs/common';

export class StapleService {
  private readonly logger = new Logger(StapleService.name);

  // ...

  this.logger.debug({ skillId, sessionId }, 'skill invoked');
  this.logger.error({ err }, 'sanitizer failed');
}
```

Never log raw user message content. Log structured fields (ids, counts, durations) instead.

## Async

`async`/`await` everywhere. Never mix with `.then()`. Even when wrapping a synchronous library, repository methods are declared `async` so the calling API stays consistent.

## Error Handling

Throw typed errors from repositories and services. Translate to `HttpException` subclasses only at the controller layer.

```typescript
// Repository
export class SessionNotFoundError extends Error {
  constructor(public readonly sessionId: string) {
    super(`Session not found: ${sessionId}`);
  }
}

// Service - lets typed error bubble
async getSession(id: string): Promise<Session> {
  const session = this.sessions.findById(id);
  if (!session) throw new SessionNotFoundError(id);
  return session;
}

// Controller - translates to HTTP
@Get(':id')
async getOne(@Param('id') id: string) {
  try {
    return await this.service.getSession(id);
  } catch (err) {
    if (err instanceof SessionNotFoundError) throw new NotFoundException(err.message);
    throw err;
  }
}
```

Never silently swallow errors. Never catch and re-throw without adding context.

## No `any`

Wrong pattern:

```typescript
function process(data: any) { ... }
const result = response as any;
```

Failure mode: type errors move from compile time to runtime.

Correct alternative: use `unknown` with explicit narrowing, or isolate the untyped surface behind a typed wrapper.

## String-Interpolated SQL

Wrong pattern:

```typescript
const results = db.prepare(`SELECT * FROM users WHERE id = ${userId}`).all();
```

Failure mode: SQL injection.

Correct alternative: parameterized query with `?` positional or `@name` named placeholders.

```typescript
// CORRECT
const findUser = db.prepare('SELECT * FROM users WHERE id = ?');
const results = findUser.get(userId);
```

## Env Vars Outside Config

Wrong pattern:

```typescript
const apiKey = process.env.API_KEY;
```

Failure mode: the env var is accessed before validation runs.

Correct alternative: inject validated config via a config module/provider.

---

Extends `common/coding-style.md` and `typescript/coding-style.md`. Adapt paths in the frontmatter to match your project structure.
