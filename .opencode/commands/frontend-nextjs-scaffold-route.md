---
description: Scaffold a new Next.js 16 App Router route (page + optional layout/loading/error) following team conventions.
---

Scaffold a new App Router route for: $ARGUMENTS

Follow team conventions:
- Create `app/<segment>/page.tsx` as a Server Component by default.
- Add `loading.tsx` and `error.tsx` when the route fetches data.
- If the route needs mutations, add a Server Action with zod input validation.
- Type everything; run prettier + eslint before reporting done.

Ask for the route path if `$ARGUMENTS` is empty. Show the files you plan to create before writing them.
