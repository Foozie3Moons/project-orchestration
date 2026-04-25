---
paths:
  - "**/*.ts"
---

# Nest.js Backend Layering

Pocket reference for layered architecture in Nest projects.

## Five-Layer Module Structure

Every module uses this directory structure:

```
src/backend/<module>/
├── api/           (1) @Controller endpoints and @MessagePattern handlers — inbound only
├── use-case/      (2) OPTIONAL — composite workflows spanning multiple application services
├── application/   (3) Single-transaction orchestration; one service owns one business operation
├── data-access/   (5) Repositories (database) and outbound gateways (HTTP/SDK clients)
└── domain/        (4) Entities, value objects, pure business rules — no I/O, no Nest imports
```

Layers are numbered 1→5 in the direction allowed imports flow. A higher-numbered layer never imports from a lower-numbered one. Layer skipping is forbidden — `api/` must not reach `data-access/` directly even if the application service is a one-line passthrough. Write the passthrough. Any layer a module does not need may be omitted.

## Intra-Module Dependency Arrows

```
api ──▶ use-case ──▶ application ──▶ data-access ──▶ domain
 │         │              │               │             ▲
 └─────────┴──────────────┴───────────────┴─────────────┘
              (all layers may import domain directly)

core ◀── any layer, any module
```

Specific constraints:

- `api/` imports from `use-case/` (if present) or `application/`, plus `domain/` and `core/`.
- `use-case/` imports from `application/`, `domain/`, `core/`. Never `data-access/`. Never a peer `use-case/`.
- `application/` imports from `data-access/`, `domain/`, `core/`. Never `api/`, `use-case/`, or a peer `application/` in the same module.
- `data-access/` imports from `domain/` and `core/` only.
- `domain/` imports from `core/types/*` only — pure types and utilities, nothing stateful.

## Cross-Module Rules

A module is opaque except through two surfaces: its `application/` services and its `domain/` types.

| From module A → module B                  | Allowed? |
|-------------------------------------------|----------|
| `a/application/*` → `b/application/*`    | Yes — the only behavioral cross-module call |
| Any layer of A → `b/domain/*`            | `import type` only — published language |
| Any layer of A → `b/api/*`              | No — API is inbound surface |
| Any layer of A → `b/use-case/*`          | No — UseCases are private composition |
| Any layer of A → `b/data-access/*`       | No — Data Access is private storage |

Domain values (instances) enter module A only as return values from B's `application/` services.

## Transport

`src/backend/transport/` holds long-running **inbound** adapters (message transports, queue consumers). These are not module layers.

- Transports know nothing about any module's internals.
- They dispatch into `api/` handlers via `@MessagePattern`.
- No module may import from a transport. The transport → module direction is the only legal edge.

## Core

`src/backend/core/` holds cross-cutting infrastructure: config, logging, database provider, migration runner, global exception filters.

- Any layer of any module, and any transport, may import from `core/`.
- `core/` may not import from any module or transport.
- `domain/` is limited to `core/types/*` (pure types and utilities).

## Vocabulary

**Gateway** — owns the external system's wire handle (SDK client, HTTP transport, socket). One gateway per external system. Always in `data-access/`. Named `<system>.gateway.ts`.

**Adapter** — implements a port interface from `domain/` but does not own a wire handle. Layer placement determined by imports.

**Use-case** — composes **multiple application services** across a composite workflow. A use-case with only one service call is not a use-case — call the application service from `api/` directly.

---

Adapt paths in the frontmatter to match your project structure.
