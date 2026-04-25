---
paths:
  - "src/frontend/**/*.ts"
  - "src/frontend/**/*.tsx"
  - "src/frontend/**/*.js"
  - "src/frontend/**/*.jsx"
---
# React Hooks

> Extends [common/hooks.md](../common/hooks.md) with React-specific conventions.

## Rules of Hooks

- Only call hooks at the top level — never inside loops, conditions, or nested functions
- Only call hooks from React components or other custom hooks
- All custom hooks use the `use` prefix

## When to Extract a Custom Hook

Extract logic into a custom hook when:
- The same stateful logic is needed in 2+ components
- A component contains data fetching, side effects, or non-trivial derived state
- A component's logic exceeds ~20 lines alongside its render

Keep hooks in a `hooks/` directory colocated with the feature, or in a shared `hooks/` package for cross-feature hooks.

## Data Fetching

NEVER fetch in `useEffect` + `useState`. Use React Query:

```tsx
// Bad
const [data, setData] = useState(null);
useEffect(() => { fetch('/api/orders').then(r => r.json()).then(setData) }, []);

// Good
const { data, isLoading, error } = useOrderList();
```

Encapsulate `useQuery` / `useMutation` calls inside a named custom hook. Components should not call `useQuery` directly.

## Effect Discipline

`useEffect` is for synchronizing with external systems — not for deriving state:

```tsx
// Wrong: filtering in an effect
useEffect(() => {
  setFiltered(items.filter(i => i.active));
}, [items]);

// Right: derive inline
const filtered = useMemo(() => items.filter(i => i.active), [items]);
```

```tsx
// Wrong: resetting state on prop change via effect
useEffect(() => { setPage(0); }, [filters]);

// Right: use key prop to reset component state
<ResultsTable key={filterHash} filters={filters} />
```

Valid `useEffect` uses: syncing to localStorage, setting up subscriptions, triggering imperative DOM APIs on mount.

## Memoization

USE `useMemo` for computationally expensive derivations (sorting, grouping, heavy filtering):
- Do NOT memoize simple property access, string concatenation, or trivial transforms

USE `useCallback` for handlers passed to memoized children:
- Do NOT `useCallback` every handler by default — only when referential stability matters

USE `useRef` for values read inside callbacks but not needed in render:
- Mutable values that must not trigger re-renders (timers, previous values, imperative handles)

Do not memoize as a default. Memoize when you have a measured problem or a referential stability requirement.

## Custom Hooks Pattern

```typescript
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)
  useEffect(() => {
    const handler = setTimeout(() => setDebouncedValue(value), delay)
    return () => clearTimeout(handler)
  }, [value, delay])
  return debouncedValue
}
```

---

Adapt paths in the frontmatter to match your project structure.
