# Project requirements

The project is a Sri Lanka travel itinerary planner. Its goal is to personalize itineraries using traveler preferences, machine learning, and route optimization. The Flutter app currently shows attractions and collects preferences. Its preference form previews the entered data locally.

## AUTH-01 Traveler signup and login

- On launch, the mobile app offers login and a signup option. Signup requires an email address and a password of at least 15 Unicode code points and at most 1,024 UTF-8 bytes.
- The API treats email addresses as case-insensitive and ignores surrounding whitespace. An email can have one account. Duplicate signup gives the traveler a login prompt.
- Successful signup or login opens the existing travel home. Invalid login returns a generic credentials error. Validation and connectivity errors appear in the form, and only one submission can be in progress at a time.
- The mobile session lasts up to 24 hours and stays in memory for the life of the app process. Travelers can log out from Home. A successful logout revokes the session and returns to login.
- The API can return the profile associated with a valid session. Missing, expired, and revoked sessions cannot access the profile.
- Email verification, password recovery, and persistent mobile sign-in are outside the initial release scope.

Acceptance checks cover signup, duplicate email with different casing, invalid credentials, successful login, authenticated profile retrieval, expiry, logout, and rejection of a revoked token.

## ARCH-01 Application structure

- Backend API endpoints delegate HTTP handling to controllers, application rules to services, and database access to repositories.
- Flutter code is grouped by feature, with separate presentation and data responsibilities and shared networking under core.
- Acceptance checks cover the existing authentication flow, reading attractions, and accessing the trip preference form. Existing API contracts and session behavior apply after the refactor.
