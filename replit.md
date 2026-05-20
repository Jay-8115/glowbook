# GlowBook

A production-ready multi-vendor hair salon booking marketplace where customers discover and book services, and salon owners manage their business.

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — run the API server (port 8080)
- `pnpm --filter @workspace/mobile run dev` — run the Expo mobile app
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from the OpenAPI spec
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)
- Required env: `DATABASE_URL` — Postgres connection string, `SESSION_SECRET` — JWT signing secret

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- Mobile: Expo 54 / React Native (slug: `mobile`)
- API: Express 5 (slug: `api-server`, port 8080)
- DB: PostgreSQL + Drizzle ORM
- Auth: JWT (bcrypt passwords, stored in AsyncStorage)
- Validation: Zod (`zod/v4`), `drizzle-zod`
- API codegen: Orval (from OpenAPI spec → React Query hooks)
- Build: esbuild (CJS bundle)

## Where things live

- `lib/db/src/schema/index.ts` — source of truth for all DB tables
- `artifacts/api-server/src/openapi.yaml` — OpenAPI spec (source of truth for API contracts)
- `artifacts/api-server/src/routes/` — Express route handlers (auth, users, categories, salons, services, staff, bookings, reviews)
- `artifacts/mobile/app/` — Expo Router screens: `(tabs)/` for main nav, `salon/[id]`, `booking/[id]`, `booking/new`, `auth/`, `owner/`
- `artifacts/mobile/components/` — shared UI components (SalonCard, BookingCard, CategoryChip, etc.)
- `artifacts/mobile/constants/colors.ts` — design tokens (primary: #C9A84C gold, bg: #0A0A0A, card: #1A1A1A)
- `artifacts/mobile/context/AuthContext.tsx` — JWT auth state + AsyncStorage persistence
- `lib/api-client-react/src/generated/` — auto-generated hooks (never edit manually)

## Architecture decisions

- **Contract-first API**: OpenAPI spec → Orval codegen → typed React Query hooks. Screens consume generated hooks, never raw fetch.
- **No Link component on web**: Expo Router's `<Link>` renders `<a>` tags which conflict with React Native Web's indexed CSS setter. All navigation uses `router.push()` from `expo-router`.
- **Platform-safe animations**: `useNativeDriver` is guarded with `Platform.OS !== 'web'` in every `Animated.timing` call.
- **iOS-only tab layout removed**: `expo-glass-effect`, `expo-symbols`, and `expo-router/unstable-native-tabs` are iOS-only; the tab layout uses only cross-platform `Tabs` + `Feather` icons.
- **KeyboardProvider removed**: `react-native-keyboard-controller`'s `KeyboardProvider` breaks web; removed from root layout (only used natively via `KeyboardAwareScrollViewCompat`).

## Product

- **Discovery**: Browse trending, nearby, and top-rated salons; filter by category or search by name/service
- **Salon detail**: Hero image, services with prices/duration, staff picker, ratings and reviews
- **Booking**: Pick service → staff → time slot → confirm; view and cancel existing bookings
- **Favorites**: Save salons for quick access
- **Auth**: Register as customer or salon owner; JWT stored in AsyncStorage
- **Owner dashboard**: Manage salon profile, view bookings, accept/decline/complete appointments
- **Seed data**: 6 categories, 6 salons, 20 services, 15 staff; demo accounts `owner@glowbook.com` and `jane@glowbook.com` (password: `password123`)

## User preferences

_Populate as you build — explicit user instructions worth remembering across sessions._

## Gotchas

- Never use `<Link>` from `expo-router` in components — use `router.push()` instead (web `<a>` tag causes a CSS indexed property crash)
- `useNativeDriver` must always be guarded: `Platform.OS !== 'web'`
- Do not add `KeyboardProvider` back to root layout — it breaks web
- `gap` in StyleSheet is fine on web with this version of RN Web
- Expo Router tab items render as `<a>` tags internally on web, so avoid passing incompatible styles

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
