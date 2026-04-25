---
paths:
  - "src/frontend/**"
---

# React Aesthetics

## Banned Defaults

Use: a deliberately-chosen font, a deliberately-chosen palette, and CSS that matches your project's identity. For any concern not yet chosen, do not invent a default. Ask the user, or defer the surface.

Do not use:
  - `font-family: "Inter", sans-serif` — Inter is the default tutorial font and signals "generic SaaS".
  - `font-family: "Roboto", sans-serif` — same reason.
  - `font-family: Arial, sans-serif` — 1990s web-safe default.
  - `font-family: system-ui, -apple-system, "Segoe UI", Roboto, ...` — the "system font stack" produces a look that changes by OS and has no project identity.
  - Purple-to-pink or blue-to-purple gradients on white backgrounds — the dominant AI-generated-marketing-page aesthetic.
  - Any component-library default theme applied without a deliberate theme layer on top.

Why the wrong patterns are tempting: every frontend tutorial, every component-library README, and every LLM-generated starter template reaches for these defaults.

Failure mode: visual identity collapse — the product looks like every other Tailwind-starter-plus-shadcn project.

Mechanical enforcement: review only.

## No New Top-Level Frontend Dependencies Without a Task

Use: the dependencies already in the frontend's `package.json`. If a new surface needs motion, icons, typography loading, or styling utilities, stop and flag.

Do not use: `npm/pnpm/yarn add <anything>` in the frontend tree unless the dispatched task brief explicitly names the dependency and the reason.

Failure mode: frontend surface area explodes. Multiple agents each add their own motion library, their own icon set, their own CSS-in-JS runtime.

## Cohesion Across Frontend Subagents

Multiple agents may ship frontend verticals. These must converge on a shared aesthetic, not diverge into visually-distinct products. When one agent introduces a visual choice (a new color, a new spacing scale, a new type weight, a transition curve), the others inherit it. Match what is already in the codebase rather than inventing a new variant.

Divergence is a review-blocker.

---

Adapt paths in the frontmatter to match your project structure.
