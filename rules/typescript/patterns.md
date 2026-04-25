---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# TypeScript/JavaScript Patterns

> This file extends [common/patterns.md](../common/patterns.md) with TypeScript/JavaScript specific content.

## API Response Format (Frontend / Non-Nest)

For frontend code consuming external APIs and for non-Nest backend services:

```typescript
interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
  meta?: {
    total: number
    page: number
    limit: number
  }
}
```

For Nest backends, this is overridden — see `nestjs/patterns.md`.

## Repository Pattern

Repositories use named domain methods, not generic CRUD. The generic interface below is intentionally NOT used:

```typescript
// NOT USED - kept here only as a reference for what to avoid
interface Repository<T> {
  findAll(filters?: Filters): Promise<T[]>
  findById(id: string): Promise<T | null>
  create(data: CreateDto): Promise<T>
  update(id: string, data: UpdateDto): Promise<T>
  delete(id: string): Promise<void>
}
```

Use named methods instead. See `nestjs/patterns.md` for the full pattern with examples.

---

Extends `common/patterns.md`. Further extended by `nestjs/patterns.md` for Nest backend code (which adds prepared statements, ORM ban, Nest-specific API response format, and lifecycle hooks). Where `nestjs/patterns.md` conflicts with this file, the nestjs file wins for Nest code.
