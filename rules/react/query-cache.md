---
paths:
  - "src/frontend/**/*.ts"
  - "src/frontend/**/*.tsx"
  - "src/frontend/**/*.js"
  - "src/frontend/**/*.jsx"
---
## Derived State Must Not Live in the Cache

Query caches hold **raw server data only**. View-layer classifications — active/inactive splits, visibility flags, filtered subsets, sorted orders — are never stored in query cache shape or as separate cache entries.

Derived state is computed at render time from cached raw data using pure functions.

### Canonical pattern

```typescript
// Cache holds raw data
queryClient.setQueryData(['resource', id], rawItems: Map<string, Item>)

// Derived state computed in component or custom hook
const visibleItems = useMemo(() => computeVisible(rawItems), [rawItems])

// Never classify into view buckets inside cache
{ activeItems: Item[], inactiveItems: Item[] }  // wrong cache shape

// Never patch view state during mutations
onMutate: () => {
  // moving items between active/inactive arrays — wrong
}
```

### Mutations patch raw fields only

Optimistic updates set exactly the field the API call changes (e.g. `status`, `assignee`). They do not reclassify, reorder, or restructure the cached data. The view recomputes from the patched raw value on next render.

### One cache target per mutation

A mutation invalidates the single cache entry that owns the changed resource. Bulk/aggregate caches are populated on initial fetch only and are never patched by mutations.

---

Adapt paths in the frontmatter to match your project structure.
