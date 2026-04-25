---
paths:
  - "src/backend/**/*.ts"
  - "src/backend-for-frontend/**/*.ts"
---

# Nest.js Modules

How to structure a bounded context module.

Layer placement and cross-module rules: see `./layering.md`.

## One Bounded Context, One Module

Each bounded context lives under `src/backend/<module>/` with its module file at the root:

```
src/backend/users/users.module.ts
src/backend/orders/orders.module.ts
src/backend/notifications/notifications.module.ts
```

A module declares the providers, controllers, and exports for its bounded context. It does NOT declare providers from other contexts — it imports them via other modules.

## Module Anatomy

The module file sits at the module root. Providers are drawn from the layered subdirectories. `exports:` is limited to application services (behavioral surface), domain types (published language), and port interfaces — never repositories, gateways, or internal use-case classes.

```typescript
@Module({
  imports: [
    DatabaseModule,
    AuthModule,
  ],
  providers: [
    // data-access/
    OrderRepository,
    PaymentGateway,
    // application/
    OrderService,
    CheckoutService,
  ],
  controllers: [
    OrderController,
  ],
  exports: [
    // Only application services other modules need
    OrderService,
  ],
})
export class OrdersModule {}
```

## Export Discipline

Export the minimum surface area. Repositories stay private to the module unless another bounded context genuinely needs direct access (rare — usually they should go through a service).

If you find yourself exporting a repository, ask: should this be a service method instead?

## Imports

Import other modules, not their providers directly. Nest's DI resolves the providers through the module graph.

```typescript
// CORRECT
@Module({
  imports: [OrdersModule],
  providers: [ShippingService],  // ShippingService can inject OrderService
})

// WRONG
@Module({
  providers: [
    ShippingService,
    OrderService,  // duplicating a provider from another module
  ],
})
```

## Global Modules

Use `@Global()` sparingly. Justified for: `ConfigModule`, `LoggingModule`, possibly `DatabaseModule`. NOT justified for domain modules — making them global hides the dependency relationship.

## Forward References

`forwardRef()` is a fallback for circular dependencies, not a default. If you need it, the design is probably wrong. Try first:

1. Extract the shared piece to `shared/`
2. Invert one dependency direction
3. Define an interface in the dependent module that the dependency module implements

Only after these fail, use `forwardRef`. Document why in a comment.

## Dynamic Modules

Use dynamic modules (`forRoot()`, `forFeature()`) when a module needs configuration at registration time. Most modules don't need this — they pull config from the global `ConfigModule`.

## Module Tests

Don't test module shells. A test that asserts `expect(module.get(MyService)).toBeDefined()` verifies that Nest's DI works, which is not your job. Test the providers inside the module instead.

---

Adapt paths in the frontmatter to match your project structure.
