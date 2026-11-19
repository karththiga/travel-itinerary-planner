# travel-itinerary-planner
Context Aware Personalized Travel Itinerary Planner Using Machine Learning and Route Optimization for Sri Lanka

## Local development

Set `MONGODB_URI` in `backend/.env` to your MongoDB connection string, then run:

```sh
cd backend
npm ci
node server.js
```

The server defaults to port 3000. Set `PORT` to override it. From `mobile/`, run `flutter pub get` and `flutter run` on the Android emulator. For a different API address, pass `--dart-define=API_BASE_URL=https://your-api.example.com` with the actual URL and no trailing slash.

## Project records

- [Project requirements](docs/requirements.md)
- [Technical decisions](docs/technical-decisions.md)
- [Agent and documentation update instructions](AGENTS.md)
