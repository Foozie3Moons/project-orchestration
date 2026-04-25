---
paths:
  - "src/frontend/**/*.ts"
  - "src/frontend/**/*.tsx"
  - "src/frontend/**/*.js"
  - "src/frontend/**/*.jsx"
---
# React Coding Style

> Extends [common/coding-style.md](../common/coding-style.md) with React-specific conventions.

## Component Structure

SEPARATE container and presentation concerns:
- Containers own state, data fetching, and event handlers
- Presentation components receive props and render — no fetching, no side effects
- One component per file; filename matches the exported component name

## Component Sizing

KEEP components focused:
- Extract a subcomponent when a render function exceeds ~50 lines
- Extract a custom hook when stateful logic is reused or exceeds ~20 lines
- If a file exceeds ~150 lines, it is doing too much — split it

## Props

DEFINE props as a named interface above the component:

```tsx
interface UserCardProps {
  userId: string;
  onSelect: (id: string) => void;
}

export function UserCard({ userId, onSelect }: UserCardProps) { ... }
```

PREFER discriminated unions over optional props that are only valid together:

```tsx
// Prefer
type ButtonProps =
  | { variant: 'link'; href: string }
  | { variant: 'action'; onClick: () => void };

// Avoid
interface ButtonProps {
  variant: 'link' | 'action';
  href?: string;
  onClick?: () => void;
}
```

## JSX Conventions

- Destructure props in the function signature
- Use explicit `return` for multi-line JSX
- Use early returns for loading / error / empty states before the main render path
- Never use array index as `key` when items can reorder or be removed

## Conditional Rendering

AVOID patterns that cause unnecessary unmount/remount cycles:
- Prefer hiding (`display: none` or opacity) over conditional mounting for frequently toggled UI
- Use conditional mounting for content that is expensive to keep alive when hidden

## Naming

- Components: PascalCase
- Hooks: `use` prefix, camelCase (`useOrderSummary`)
- Event handlers: `handle` prefix (`handleSubmit`, `handleRowSelect`)
- Boolean props: `is` / `has` prefix (`isLoading`, `hasError`)

## Styling

ALL styling goes through CSS Modules. JSX `style={}` is banned except for the CSS-custom-property escape hatch.

### No JSX `style={}`

Forbidden:

```tsx
<div style={{ padding: "var(--space-3)" }} />                  // pure static — use .module.css
<div style={{ opacity: disabled ? 0.4 : 1 }} />                // state-driven — use :disabled / data-*
```

Permitted (only shape — object whose every key starts with `--`):

```tsx
<div style={{ "--row-height": `${h}px` } as React.CSSProperties} />
```

### Semantic class names

Class names inside `.module.css` describe the element's role in the component. Banned exact identifiers:

- `.container`
- `.wrapper`
- `.box`
- `.inner`
- `.outer`

Use component-specific names: `.inputBar`, `.chatPage`, `.messageBubble`, `.errorPanel`.

---

Adapt paths in the frontmatter to match your project structure.
