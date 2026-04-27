---
globs: ["**/*.ts", "**/*.tsx"]
---

# Frontend Rules (React 19 + Vite + TypeScript)

## Stack
- React 19 + TypeScript strict mode. Vite 6. `npm` for packages (fnm for Node version).
- TanStack Query v5 for server state — no manual loading/error state
- zod for runtime validation
- React 19 Actions + `useActionState` for forms

## Patterns
- Co-locate component files: `components/Foo/{index.tsx, hook.ts, types.ts, test.tsx}`
- All API calls through `src/api/` — never inline `fetch`
- No `any` — use `unknown` + type guards
- `useOptimistic` for optimistic UI where appropriate

## Testing
- vitest + @testing-library/react
- `npm run typecheck` (`tsc --noEmit`) must pass before every commit
