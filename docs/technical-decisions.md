# Technical decisions

## 2026-11-19 · Email and password authentication · AUTH-01

- Express handles account endpoints under `/api/auth`. MongoDB stores users and sessions. Startup waits for the database and creates the authentication indexes before accepting requests so the unique email constraint is in force during signup.
- Node's asynchronous scrypt derives password hashes with per-account random salts. MongoDB enforces uniqueness on normalized email. If creating the session fails after the account is saved, the traveler can log in with the new account.
- Each login or signup issues a 32-byte random bearer token. MongoDB stores only its SHA-256 digest. Sessions expire after 24 hours, with a TTL index for cleanup and an explicit expiry check on profile requests. Logout deletes that session. Mobile holds the token in memory and resets its navigation on logout or expiry.
- Signup and login share a fixed one-minute window with up to 10 requests per source IP in each Express process. When deploying behind a proxy or across replicas, configure source IP handling for the actual topology and enforce shared throttling at the ingress.
- The mobile client uses the existing HTTP package. `API_BASE_URL` configures the base URL for authentication and attractions. Debug Android builds permit HTTP to the local server. Profile and release builds require HTTPS for authentication. Deploy the backend behind HTTPS for those builds.
- The existing attractions and preferences APIs retain their public access. Future endpoints that store per-user data must verify the bearer session on the server and use its user ID.

### Authentication API

| Method and path | Input | Success | Error responses |
| --- | --- | --- | --- |
| POST `/api/auth/signup` | JSON `email`, `password` | 201 with `token`, `expiresIn` in seconds, and `user` | 400 validation, 409 duplicate, 429 rate limit |
| POST `/api/auth/login` | JSON `email`, `password` | 200 with the same fields as signup | 401 invalid credentials, 429 rate limit |
| GET `/api/auth/me` | `Authorization: Bearer <token>` | 200 with `user` | 401 missing, invalid, or expired session |
| POST `/api/auth/logout` | `Authorization: Bearer <token>` | 204, including repeat requests with the same token | 401 missing or malformed token |

The `user` object contains `id` and `email`. Account-service failures return 503. Authentication responses carry `Cache-Control: no-store`.

## 2026-11-19 · Application layers and feature directories · ARCH-01, AUTH-01

- The backend uses `routes/` → `controllers/` → `services/` → `repositories/` → `models/`. Routes wire handlers and HTTP middleware, controllers translate requests and responses, services implement application rules, and repositories own Mongoose queries and model serialization. Preferences are validated in a service and returned directly because the current endpoint has no persistence. `app.js` assembles Express and `server.js` handles database readiness and startup.
- Flutter uses `app/` for dependency wiring and the session gate, `core/network/` for HTTP transport and API configuration, and `features/<feature>/` for feature code. Widgets and screen state live in `presentation/`, and feature repositories and models live in `data/`. The auth repository owns the observable in-memory session and expiry timer. The preferences feature currently has presentation code only because its form previews data locally.
- Flutter dependencies are supplied through constructors. The app creates one HTTP client and shares the API service across feature repositories. Widget tests inject a mock HTTP client so the production repositories and request mapping are exercised. Extract dedicated view models as screen logic grows. [Flutter app architecture guide](https://docs.flutter.dev/app-architecture/guide)
