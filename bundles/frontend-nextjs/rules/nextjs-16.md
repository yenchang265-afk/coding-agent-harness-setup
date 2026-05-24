## Frontend — Next.js 16 + React

### Architecture
- App Router only (`app/`). Components are Server Components by default; add `"use client"` only when you need state, effects, or browser APIs.
- Keep data fetching in Server Components / Route Handlers / Server Actions. Never fetch with secrets from a Client Component.
- Co-locate route code under `app/<segment>/`: `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`.

### Data & caching
- Be explicit about caching: Next.js 16 defaults `fetch` to uncached, so opt into caching deliberately (`cache`, `next.revalidate`) and document why.
- Use Server Actions for mutations; revalidate with `revalidatePath`/`revalidateTag` instead of manual refetch hacks.
- Validate every Server Action input (e.g. zod) — Server Actions are public endpoints.

### TypeScript & quality
- `strict` mode on; no `any` without a `// reason:` comment. Prefer `unknown` + narrowing.
- Components are typed function components; avoid `React.FC`.
- ESLint (`next/core-web-vitals`) + Prettier must pass. No disabled rules without justification.

### Performance & a11y
- Use `next/image` and `next/font`; never raw `<img>` for app assets.
- Server-render data-dependent UI; reserve client fetching for genuinely interactive widgets.
- Every interactive element is keyboard-accessible and labelled.

### Security
- Secrets only in server-side env (no `NEXT_PUBLIC_` for anything sensitive).
- Never interpolate user input into `dangerouslySetInnerHTML`.
