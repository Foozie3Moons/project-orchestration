---
paths:
  - "src/frontend/**/*.ts"
  - "src/frontend/**/*.tsx"
  - "src/frontend/**/*.js"
  - "src/frontend/**/*.jsx"
---
# React Testing

> Extends [common/testing.md](../common/testing.md) with React-specific conventions.

## Tooling

- **Components**: Vitest + React Testing Library
- **Hooks**: `renderHook` from RTL
- **API mocking**: msw — do not mock `fetch` or axios directly
- **React Query**: wrap in `QueryClientProvider` with a fresh `QueryClient` per test

## What to Test

Test behavior, not implementation:
- User interactions (clicks, keyboard input, form submission)
- Conditional rendering (loading / error / data states)
- Data transformations surfaced to the UI (filtering, sorting, derived labels)
- Navigation flows between screens or views

## What Not to Test

- React Query's internal caching or refetch behavior
- Third-party library internals
- Exact style values or class names
- Implementation details of hooks (internal state shape, intermediate values)

## Queries

Prefer accessible queries in this order: `getByRole`, `getByLabelText`, `getByText`, `getByTestId`. Use `getByTestId` only as a last resort.

## Async

Use `waitFor` / `findBy*` for async state updates. Do not use arbitrary `setTimeout` or `act` wrappers to paper over async behavior.

## Mocking

Mock at system boundaries:
- API: msw handlers, not module mocks of fetch clients
- Modules: only when the module has an unavoidable side effect
- Time: `vi.useFakeTimers()` for debounce / throttle / polling tests

## Hook Testing

Test custom hooks via `renderHook`:
- Test state transitions and returned values, not internal implementation
- Always wrap in required providers (`QueryClientProvider`, context providers)
- Clean up between tests — use `afterEach(() => queryClient.clear())`

## React Query Setup

```tsx
const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: false } },
});

function wrapper({ children }) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}
```

Set `retry: false` in tests — default retry behavior causes slow, flaky tests on error cases.

---

Adapt paths in the frontmatter to match your project structure.
