# travel-itinerary-planner
Context Aware Personalized Travel Itinerary Planner Using Machine Learning and Route Optimization for Sri Lanka

## Local development

Set `MONGODB_URI` in `backend/.env` to your MongoDB connection string, then run:

```sh
cd backend
npm ci
node server.js
```

On startup, the server adds any missing bundled regional attractions to the configured MongoDB catalog. The server defaults to port 3000. Set `PORT` to override it. From `mobile/`, run `flutter pub get` and `flutter run` on the Android emulator or iOS simulator. Start the iOS Simulator with `open -a Simulator` on macOS and use `flutter devices` to find its ID. See the [iOS setup](mobile/README.md) for device signing and API configuration. For a different API address, pass `--dart-define=API_BASE_URL=https://your-api.example.com` with the actual URL and no trailing slash.

## Project records

- [Project requirements](docs/requirements.md)
- [Technical decisions](docs/technical-decisions.md)
- [Agent and documentation update instructions](AGENTS.md)

Password recovery uses Resend. Configure `RESEND_API_KEY` and `PASSWORD_RESET_FROM` in the backend environment. The sender must use a verified Resend domain.

## Admin dashboard

Start the backend with its existing MongoDB configuration. Create the administrator's account using the existing signup flow, then run the following in `mongosh` connected to the backend's database. Use the account's normalized email address.

```javascript
db.users.updateOne({ email: 'admin@example.com' }, { $set: { role: 'admin' } })
```

To revoke access, set that account's role to `traveler`. Role changes apply on the next admin request. Use Node.js 20.19+ or 22.12+ to run the frontend tooling.

```sh
cd admin
npm ci
npm run dev
```

Open the URL printed by Vite and sign in with the administrator account. Run `npm run build` for the production bundle in `admin/dist`. For a separate API origin, set `VITE_API_BASE_URL` to its HTTPS URL including `/api` before building.
