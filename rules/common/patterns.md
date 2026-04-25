# Common Patterns

## Skeleton Projects

When implementing new functionality from scratch (NOT applicable to refactors of existing systems):

1. Search for battle-tested skeleton projects
2. Use parallel agents to evaluate options:
   - Security assessment
   - Extensibility analysis
   - Relevance scoring
   - Implementation planning
3. Clone best match as foundation
4. Iterate within proven structure

## Design Patterns

### Domain-Driven Design & OOP

Use classes with dependency injection for stateful domain logic:

- Each module is a self-contained bounded context with clear boundaries
- Use classes for clients, services, engines, and models
- Hide internal state behind well-defined interfaces; expose behavior, not data
- Accept dependencies via constructor, never construct them internally
- Each class has one reason to change; split responsibilities into collaborators
- Favor composition over deep class hierarchies
- Put business logic on domain objects, not in procedural service layers
- Use interfaces/contracts defined by the consuming side, not the provider

### Repository Pattern

Repositories use named domain methods, not generic CRUD. See `typescript/patterns.md`
§Repository Pattern and `nestjs/patterns.md` §Repository Pattern for the full pattern
with examples.

---

Universal design patterns only. Extended by `typescript/patterns.md` for TypeScript-specific patterns, and further by `nestjs/patterns.md` for Nest backend code. Where those files conflict with this one, the more specific file wins.
