---
paths:
  - "src/frontend/**/*.ts"
  - "src/frontend/**/*.tsx"
  - "src/frontend/**/*.js"
  - "src/frontend/**/*.jsx"
---
# React Patterns

> Extends [common/patterns.md](../common/patterns.md) with React-specific conventions.

## State Management

### Colocation

Keep state at the lowest owner that needs it. Do not hoist state to a parent until two or more children genuinely share it.

### Context API

Use Context for values that are stable or change infrequently and are needed across many levels:
- Auth / session
- Theme / locale
- Feature flags

Do NOT use Context as a general state manager. It re-renders all consumers on every change — use it for low-frequency values.

For server state, React Query is the source of truth. Do not duplicate server state into Context or `useState`.

### State Machines for View Screens

For multi-screen or multi-step views, use a union type + explicit state variable:

```tsx
type Screen = 'list' | 'detail' | 'confirm'
const [screen, setScreen] = useState<Screen>('list')
```

Avoids boolean flag accumulation (`isEditing`, `isConfirming`, `isDeleting`).

## Compound Component Pattern

Use when a component has multiple sections that share implicit state or context:

```tsx
<DataTable>
  <DataTable.Toolbar />
  <DataTable.Body />
  <DataTable.Pagination />
</DataTable>
```

Implement via a Context provider inside the parent + named sub-components attached as properties.

## Data Fetching

ALL data fetching goes through React Query. No raw `useEffect` fetching.

Query key conventions:
```tsx
// Entity list
queryKey: ['orders']

// Parameterized
queryKey: ['orders', orderId]
queryKey: ['orders', { status, page }]
```

Always encapsulate `useQuery` / `useMutation` in a named hook — components never call React Query directly.

Always handle all three states:
- Loading: skeleton or spinner
- Error: visible error state with recovery hint
- Data: main content

## Responsive Layout

Do NOT use JavaScript to detect screen size for layout decisions. Use CSS media queries or container queries. Reserve `useResizeObserver` / `useWindowSize` for cases that genuinely require JS-side dimensions (canvas, virtualization row height).

## Image Handling

Components that render images must handle the missing / loading state: skeleton, neutral placeholder, or explicit empty state. Never render a broken `<img>` tag.

## Microfrontend Boundaries

- Do not import directly across MFE package boundaries. Use the shared package or a defined contract.
- Each MFE owns its own `QueryClient`. Do not share query cache across MFE boundaries unless explicitly designed for it.
- Shell-level concerns (auth, global notifications, routing) belong in the host — not duplicated across MFEs.

---

Adapt paths in the frontmatter to match your project structure.
