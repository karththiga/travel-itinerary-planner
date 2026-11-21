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
| POST `/api/auth/signup` | JSON `fullName`, `phoneNumber`, `email`, `password` | 201 with `token`, `expiresIn` in seconds, and `user` | 400 validation, 409 duplicate, 429 rate limit |
| POST `/api/auth/login` | JSON `email`, `password` | 200 with the same fields as signup | 401 invalid credentials, 429 rate limit |
| GET `/api/auth/me` | `Authorization: Bearer <token>` | 200 with `user` | 401 missing, invalid, or expired session |
| POST `/api/auth/logout` | `Authorization: Bearer <token>` | 204, including repeat requests with the same token | 401 missing or malformed token |

The `user` object contains `id`, `email`, and any stored `fullName` and `phoneNumber`. Account-service failures return 503. Authentication responses carry `Cache-Control: no-store`.

## 2026-11-19 · Application layers and feature directories · ARCH-01, AUTH-01

- The backend uses `routes/` → `controllers/` → `services/` → `repositories/` → `models/`. Routes wire handlers and HTTP middleware, controllers translate requests and responses, services implement application rules, and repositories own Mongoose queries and model serialization. Preferences are validated in a service and returned directly because the current endpoint has no persistence. `app.js` assembles Express and `server.js` handles database readiness and startup.
- Flutter uses `app/` for dependency wiring and the session gate, `core/network/` for HTTP transport and API configuration, and `features/<feature>/` for feature code. Widgets and screen state live in `presentation/`, and feature repositories and models live in `data/`. The auth repository owns the observable in-memory session and expiry timer. The preferences feature currently has presentation code only because its form previews data locally.
- Flutter dependencies are supplied through constructors. The app creates one HTTP client and shares the API service across feature repositories. Widget tests inject a mock HTTP client so the production repositories and request mapping are exercised. Extract dedicated view models as screen logic grows. [Flutter app architecture guide](https://docs.flutter.dev/app-architecture/guide)

## 2026-11-19 · ExploreLanka startup and tab shell · UI-01

- A cancelable 850 ms Flutter splash precedes the session gate at process launch. A signed-in shell uses Material 3 NavigationBar and IndexedStack so tabs retain form and scroll state. Home is selected at the start of each session.
- Home and Explore share one attractions request per session, with retry in Explore. Explore filters name, location, district, and category on-device. Lesser-known discoveries appear when at least three API attractions have positive popularity scores and show up to three places from the lower half of that ranking.
- Sigiriya, Ella, and Galle are bundled editorial destinations with generated JPEG images. Their bookmarks live in the signed-in shell for this iteration. Plan reuses the existing preferences view, and Profile hosts the existing logout action.
- The built-in image generator produced Ella and Galle from these prompts:
  - Photorealistic editorial Sri Lanka travel photograph of a red railway train crossing the curved Nine Arch Bridge in Ella, surrounded by lush tropical highlands, naturally lit daytime, landscape 4:3 composition, bridge and train clearly visible within central crop, no text or watermark.
  - Photorealistic editorial Sri Lanka travel photograph of Galle Fort’s white lighthouse and historic stone ramparts above the turquoise Indian Ocean, palm trees, naturally lit sunny daytime, landscape 4:3 composition, lighthouse visible within central crop, no text or watermark.

## 2026-11-19 · Interest results and Plan redesign · UI-02

- Home opens category results as a Navigator route and retains the tab shell underneath. Category matching uses the shared catalog request and recognizes category names and common aliases. A labeled editorial suggestion is bundled for each category when results are missing. Sri Lanka Tourism informed the suggestions. [Attractions](https://www.srilanka.travel/essence/tourist-attractions) · [Nature and wildlife](https://www.srilanka.travel/food/untamed-sri-lanka) · [Local eateries](https://www.srilanka.travel/eating-places)
- The Plan tab retains its local form state and validates required selections and a positive finite budget before displaying a preview. It uses the existing Sigiriya image and ExploreLanka palette. Preview displays entered preferences, with itinerary generation outside this change.

## 2026-11-19 · Explore and attraction details · UI-03

- Explore uses the existing attractions catalog and category matching. Card and detail views share bundled images for named landmarks and use an icon for attractions without a matching image. The catalog contract and MongoDB schema remain unchanged.
- The client interprets `estimatedVisitDuration` as minutes and displays listed positive fees in LKR. The old schema defaults fees to zero, so details display zero or missing fees as “Not listed” until the catalog can distinguish free entry from unknown cost.
- Attraction bookmarks share the signed-in tab shell’s session lifetime. MongoDB IDs identify saved attractions, with a name and location tuple for records without an ID. Featured destination bookmarks retain their separate editorial identity.

## 2026-11-19 · Regional attractions and alias search · UI-04

- The backend imports nine entries from `backend/data/regionalAttractions.json` before accepting requests. The repository reuses matches by canonical name or alias, adding search aliases while preserving existing descriptions and other catalog fields. New entries use deterministic MongoDB IDs and insert-only upserts so repeat startups preserve the same records.
- `aliases` is an optional string array on attractions. Flutter searches aliases alongside the existing name, category, and location fields and accepts records that predate the field. Coordinates are approximate map points. The catalog leaves hours, access conditions, fees, and visit duration unspecified for these entries.
- Catalog references include local tourism, regional planning, and official mapping or infrastructure documents. [Koneswaram](https://www.srilanka.travel/attractions/koneswaram-kovil) · [Greater Jaffna development plan](https://www.uda.gov.lk/attachments/dev-plans-2023-2033/GreaterJaffnaDevelopmentPlanReport.pdf) · [Arugam Bay coordinates](https://documents.gov.lk/view/extra-gazettes/2023/12/2363-72_E.pdf) · [Point Pedro Jetty](https://www.coastal.gov.lk/images/pdf/POINT_Fedro_Fisheries_EIA/03022020__EIA_PPD_English.pdf) · [Sangupiddy Bridge](https://tourismnorth.lk/destinations/show/sangupiddy-bridge)

## 2026-11-19 · Regional attraction artwork and visitor details · UI-05

- Bundled JPEG illustrations and visitor guidance live in the Flutter attraction feature. The shared card and details presentation resolve editorial information from normalized catalog names and aliases. Exact names or aliases prevent unrelated places from receiving a landmark image. Missing assets fall back to the existing landscape icon.
- API-supplied durations and hours take precedence. Editorial visit ranges are labeled as suggestions, and unverified fees remain “Not listed.” Nallur’s published main-entrance hours come from Northern Province Tourism. [Nallur Kandaswamy Kovil](https://tourismnorth.lk/destinations/show/nallur-kanthaswamy-kovil) · [Koneswaram Kovil](https://www.srilanka.travel/attractions/koneswaram-kovil)

The built-in image generator used “Photorealistic illustrative editorial travel image of {subject}. Landscape 4:3, landmark centered for a square thumbnail crop, natural daytime, no text, no watermark.” The subject text for each asset was:

- `nallur.jpg` — Nallur Kandaswamy Temple in Jaffna, tall gold and ochre carved gopuram, frontal exterior from the courtyard
- `koneswaram.jpg` — Koneswaram Temple on Swami Rock in Trincomalee, colorful Hindu temple exterior on a coastal headland overlooking deep blue sea
- `arugam-bay.jpg` — Arugam Bay Beach near Pottuvil, Sri Lanka, broad curved sandy shoreline and small rolling surf with coastal palms
- `kks-beach.jpg` — Kankesanthurai Beach near Jaffna, Sri Lanka, low sandy shoreline, shallow pale turquoise water and scattered coastal palms
- `delft.jpg` — Delft Island (Neduntivu), northern Sri Lanka, natural editorial scene of free-roaming horses amid low scrub and old coral-stone walls
- `kayts.jpg` — Kayts on Velanai Island, near Jaffna, Sri Lanka, quiet coastal town and small colorful fishing boats across shallow water
- `point-pedro.jpg` — Point Pedro Jetty, Jaffna District, Sri Lanka, grounded editorial depiction of a low concrete fishing wharf extending out from a rocky northern coast
- `elephant-pass.jpg` — Elephant Pass (Aanaiyiravu) near Kilinochchi, Sri Lanka, elevated view of a straight road and causeway among broad shallow lagoon flats, no memorial or military objects
- `sangupiddy.jpg` — Sangupiddy Bridge, Sri Lanka, low road bridge with steel girder spans over the shallow Jaffna Lagoon, with flat distant banks, no suspension towers

## 2026-11-19 · Signup profile and account screen redesign · AUTH-01, UI-06

- Signup validates full name and phone before hashing and writes them with the credentials in MongoDB. The service requires them for new registrations and the schema allows them to be absent for legacy accounts. Signup, login, and authenticated profile responses expose the account’s own saved profile fields.
- Phone formatting accepts 10-digit Sri Lankan local numbers and plus-prefixed international numbers with 8 to 15 digits. The service stores local numbers with the `+94` prefix. The phone field is validated for format, and email is the account identifier.
- Flutter and Express accept passwords starting at eight Unicode code points, with the existing 1,024-byte maximum. Password confirmation is checked in Flutter and excluded from API requests. The signup contract and mobile build should be released together.
- The two forms share the existing Sigiriya asset and ExploreLanka theme. The screen switches modes locally, clears password fields when switching, and retains the signed-in navigation on successful authentication.

## 2026-11-20 · Account bookmarks · UI-07, UI-01, UI-03

- This supersedes the session-only bookmark storage in UI-01 and UI-03. MongoDB stores bookmark keys on the user record, and accounts without the field start with an empty list. Atomic add and remove operations make repeated writes idempotent. Bookmarks are available after login, with no change to the mobile session lifetime.
- Authenticated GET `/api/auth/me/bookmarks` returns `{ bookmarks }`. Authenticated PUT to the same path accepts `{ key, saved }` and returns 204. Missing or expired sessions return 401, and malformed keys or flags return 400.
- Catalog keys use the attraction ID, with a name, location, and district fallback for rows without an ID. Featured destinations use their own keys. The mobile app resolves saved cards against the catalog so they display current details. This requires a reachable catalog to open an attraction, and deleted entries remain removable.

## 2026-11-20 · Profile edits · UI-08, AUTH-01

- Authenticated PATCH `/api/auth/me` accepts `fullName`, `phoneNumber`, and `email`, with optional `currentPassword` and `newPassword`. It returns 200 with `{ user }`, 400 for validation or incorrect current password, 401 for an invalid session, and 409 for duplicate email or a concurrent credential change. It uses the existing auth request limiter.
- The service reuses signup normalization and scrypt hashing. It verifies the current password before changing the email or password and matches the previously read credentials when committing the update. Existing bearer sessions retain their normal expiry. Flutter checks confirmation locally and clears password fields after a successful save.

## 2026-11-20 · Email password recovery · AUTH-02, AUTH-01

- This supersedes the initial exclusion of password recovery. POST `/api/auth/forgot-password` accepts `email` and returns 202 for syntactically valid requests when delivery is configured. POST `/api/auth/reset-password` accepts `email`, `code`, and `password` and returns 204 on success. Both share auth throttling. Invalid inputs and expired codes return 400.
- Resend delivers through the server using `RESEND_API_KEY` and `PASSWORD_RESET_FROM` (a verified sender). Missing configuration disables new requests with 503. Delivery errors are logged without account details. Delivery starts asynchronously to keep provider latency out of the public response.
- The user record holds only a SHA-256 digest and expiry for the random 24-byte reset code. Issuance is limited to once per minute per account. A single conditional write changes the scrypt hash and consumes the code within its 15-minute lifetime. Sessions compare their recorded reset timestamp against the user’s timestamp, which invalidates pre-reset sessions without a separate write.

## 2026-11-20 · Admission labels · UI-09, UI-03

- Existing positive catalog fees remain indicative LKR amounts. Catalog authors can set `freeAdmission: true` for verified free admission. Zero historically meant unspecified, so legacy zeros use curated pricing where available and otherwise display Price not listed. An explicit false suppresses a curated Free label when a price is unavailable.
- Featured cards label the covered place or visitor tier. The Sigiriya rate uses the official foreign adult USD ticket price. Selected free public sites use published admission guidance. Optional tours, museums, parking, and transport have separate costs. [Central Cultural Fund prices](https://ccf.gov.lk/is/index.php) · [Majeste admissions](https://majeste.lk/prices) · [Kandyam Arugam Bay guide](https://kandyam.com/explore/arugam-bay)

## 2026-11-20 · Dark travel preferences screen · UI-10, UI-02

- This supersedes the Sigiriya banner and light section cards from UI-02. The Plan screen scopes a dark Material theme to its own scaffold and preview dialog. Interest tiles use the shared travel interest enum and platform emoji. Width and text scaling determine how many tiles fit in each row.
- The three-segment indicator marks the preferences screen. The primary action retains its preview label because the existing flow displays a local summary. The Plan tab keeps its existing state and navigation, and the preview parser accepts correctly grouped comma amounts as well as existing numeric input. No API or configuration changes are required.

## 2026-11-20 · Catalog recommendations and route preview · UI-11, UI-10, UI-02

- Plan now opens a recommendations route in place of the local summary. Flutter uses the shared HTTP client and a trip planning repository, reuses the attraction details and account bookmarks, and keeps removals in memory for the current shortlist.
- POST `/api/recommendations` accepts `interests`, `tripDays`, `budget`, `groupType`, `transport`, and optional `excluded` and `previous` arrays of attraction IDs. It returns `{ recommendations }` with `attraction`, `matches`, and `discovery` for each record. The existing preferences API remains available.
- Ranking uses catalog category tags and favors coverage of selected interests, different districts, and a lower-scored discovery when enough popularity data exists. It filters out individual listed admission fees above the total budget and visits whose recorded duration exceeds eight hours per trip day. Missing fee and visit data are allowed. The shortlist grows with trip duration up to 12 stops. Regeneration deprioritizes previous suggestions and excludes removed IDs. Results may repeat when the matching catalog is small. This rule-based ranking uses individual listed fees and does not estimate party costs or use group and transport for ranking.
- POST `/api/travel-route` accepts 1–12 unique `attractionIds` and returns `{ stops }`. The service starts from the first shortlisted attraction and repeatedly adds the nearest remaining coordinates. This provides an approximate visit order without a routing provider or travel-time estimates. Both endpoints return 400 for invalid input and 503 for catalog errors. They are stateless and use the existing API and MongoDB configuration.

## 2026-11-20 · Day-by-day itinerary preview · UI-12, UI-11

- The dark Flutter preview replaces the plain stop list from UI-11 and reuses the bundled Ella illustration. Flutter splits the backend's ordered stops by count across the requested days, preserving order and grouping trailing open days. The preview explains the straight-line basis of the order. The itinerary view reuses the catalog's duration and admission and the existing details flow.
- The itinerary preview adds no API or configuration changes. Saving a whole itinerary is outside this screen's scope. Travelers can continue bookmarking individual attractions through their details and recommendations.

## 2026-11-20 · Day itinerary timeline · UI-13, UI-12

- The preview and day view share the same day groups and backend stop order. Flutter builds illustrative times starting at 08:30 with a 30-minute gap between visits, a 90-minute fallback for missing visit durations, and a one-hour lunch break when a later stop falls around or after midday. Times use the device's clock format and do not validate opening hours or travel times.
- The optional schematic projects available catalog coordinates, draws straight-line connections in visit order, and lists mapped stops beneath the zoomable canvas. It requires no map provider, API changes, or configuration.

## 2026-11-20 · Route map preview redesign · UI-14, UI-13

- Flutter renders a dark offline schematic from the same catalog coordinates and backend stop order used by the itinerary. The distance badge sums great-circle distances between mapped stops. The screen explains the straight-line preview. It uses no road geometry, travel-time estimates, map provider, or API changes.

## 2026-11-20 · Account saved trips · UI-15, UI-12, UI-07

- This extends UI-12 with account trip saving. Authenticated GET and POST `/api/auth/me/trips` list and save trips. POST accepts `preferences` and ordered `attractionIds` and returns `{ trip }`. GET returns `{ trips }`. DELETE `/api/auth/me/trips/:id` removes a trip and returns 204. The account handler returns 400 for invalid inputs, 401 for expired sessions, 409 when the account reaches 30 saved trips, and 503 for service failures.
- An atomic conditional update inserts a trip into its owner's MongoDB account. A digest of normalized preferences and ordered stop IDs prevents duplicate saves, including concurrent retries. The server copies bounded catalog fields into each snapshot so the saved preview remains usable after catalog changes. Existing accounts start with an empty list.
- Flutter uses the existing authenticated transport and reopens snapshots through the same preview, timeline, and map screens used during planning. The Saved tab opens on Trips and preserves access to the account's place bookmarks under Places. No configuration changes are required.

## 2026-11-21 · React administration dashboard · ADMIN-01, AUTH-01, UI-04, UI-11, UI-15

- `admin/` is a standalone React and Vite project. It uses the existing login and logout endpoints, keeps the bearer token in memory, and checks the session against the current database role on every admin request. Existing accounts have traveler access unless an operator grants the admin role in MongoDB. A page refresh requires a fresh sign-in.
- Admin routes use controllers, services, and repositories. Under `/api/admin`, GET `/session` returns `{ user }`. GET and POST `/attractions` list and create records. PUT `/attractions/:id` replaces editable fields and PATCH `/attractions/:id/visibility` accepts `{ archived }`. GET and POST `/bookings` list and create records and PATCH `/bookings/:id/status` accepts `{ status }`. Lists use plural response keys and successful writes return one record under its singular key. Creation returns 201. Invalid input, missing session, insufficient privileges, missing records, and unexpected failures return 400, 401, 403, 404, and 503 respectively.
- Attraction archiving keeps the ID and filters the record from the existing public and planning queries. Regional seeding records a stable key on matched and inserted records so edits, alias removals, and archives survive restart. Bookings store the attraction ID and its name at creation time so historical entries remain readable after edits. Dates are stored as calendar dates and status changes can correct earlier values. Lists load in full and filter in the browser, which suits the initial catalog and booking volume.
- The Vite development server proxies `/api` to port 3000. For independent hosting, `VITE_API_BASE_URL` is an optional build-time API base URL ending in `/api`. A same-origin HTTPS deployment can serve the build output and route `/api` to Express.

## 2026-11-21 · Persistent mobile sign-in · AUTH-01, AUTH-02, UI-07

- This supersedes the process-only Flutter session from AUTH-01. After login or signup, `flutter_secure_storage` stores the bearer token and its absolute expiry in one record. Passwords and profile data stay out of that record. Android disables app backup to keep the encrypted record on its original device. [Secure storage package](https://pub.dev/packages/flutter_secure_storage)
- Startup keeps the splash visible until it reads the record and validates any unexpired token through the existing authenticated GET `/api/auth/me`. The returned profile opens Home, and the original expiry still applies. Storage read errors, connectivity errors, and temporary API failures offer a retry. This requires a reachable API to restore access to account data on launch.
- Local expiry and a server 401 discard the saved session. Successful logout revokes the server session and clears its device record. Password reset continues to invalidate the saved token on the server. No backend contract or expiry policy changes are required.

## 2026-11-21 · iOS Flutter runner · MOB-01, AUTH-01, ARCH-01

- The Flutter iOS runner uses the shared Dart app and targets iOS 15 or later. The Xcode project uses the development bundle ID `com.example.explorelanka`. Device signing and distribution require a development team and a bundle ID registered to that team.
- The runner uses Keychain entitlements in Debug, Profile, and Release so the existing secure storage repository can persist sign-in tokens on iOS. It specifies no custom shared access group. [Secure storage setup](https://pub.dev/packages/flutter_secure_storage)
- The standard `API_BASE_URL` build option takes precedence on both platforms. Without it, Android uses `http://10.0.2.2:3000` and iOS uses `http://localhost:3000` for simulator development. The iOS runner permits local networking through App Transport Security. The existing HTTPS check still applies to authentication in profile and release. There are no backend contract changes. [Apple local networking settings](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowslocalnetworking)
