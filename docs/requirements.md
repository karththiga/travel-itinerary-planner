# Project requirements

The project is a Sri Lanka travel itinerary planner. Its goal is to personalize itineraries using traveler preferences, machine learning, and route optimization. The Flutter app shows attractions, collects preferences, and requests personalized recommendations and a suggested visit order.

## AUTH-01 Traveler signup and login

- On launch, the mobile app offers login and a signup option. Signup requires a full name, phone number, email address, and a password of at least eight Unicode code points and at most 1,024 UTF-8 bytes. The mobile form requires password confirmation.
- Signup accepts Sri Lankan local numbers and international numbers with a country code. MongoDB stores the trimmed name and normalized number with the account. Existing accounts can still log in with email and password.
- The API treats email addresses as case-insensitive and ignores surrounding whitespace. An email can have one account. Duplicate signup gives the traveler a login prompt.
- Successful signup or login opens the existing travel home. Invalid login returns a generic credentials error. Validation and connectivity errors appear in the form, and only one submission can be in progress at a time.
- The mobile session lasts up to 24 hours from sign-in and can resume after a force-close or restart. On launch, the app verifies the saved session with the server before opening Home. Missing, expired, and revoked sessions return to login. If verification temporarily fails, the app keeps the session and shows a retry action. Travelers can log out from Profile. A successful logout revokes the session and returns to login.
- The API can return the profile associated with a valid session. Missing, expired, and revoked sessions cannot access the profile.
- Password recovery is specified in AUTH-02. Email verification is outside the current scope.

Acceptance checks cover profile persistence, password confirmation, legacy login, duplicate email with different casing, invalid credentials, successful login, authenticated profile retrieval, restoration after an app restart, retry after a temporary verification failure, expiry, logout across restarts, and rejection of a revoked token.

## ARCH-01 Application structure

- Backend API endpoints delegate HTTP handling to controllers, application rules to services, and database access to repositories.
- Flutter code is grouped by feature, with separate presentation and data responsibilities and shared networking under core.
- Acceptance checks cover the existing authentication flow, reading attractions, and accessing the trip preference form. Existing API contracts and session behavior apply after the refactor.

## UI-01 ExploreLanka startup and Home

- Launch shows a branded splash before the login screen. Successful login or signup opens Home with five bottom tabs, Home, Explore, Plan, Saved, and Profile.
- Home uses the ExploreLanka orange, cream, and teal palette. It presents destination search, a Sigiriya feature with a Plan My Trip button, eight interest shortcuts, and illustrated cards for Ella and Galle. When the attractions API has enough places with popularity scores, Home also shows lesser-known discoveries.
- Search opens Explore and filters the existing attractions catalog. Each interest shortcut opens a dedicated list of places for that interest and offers a labeled destination suggestion when the catalog has no match. Plan My Trip opens the existing preferences form in Plan. Travelers can bookmark featured destinations and view or remove them in Saved (see UI-07). Profile provides account editing and logout (see UI-08).
- Acceptance checks cover the splash, signup and login landing on Home, bottom navigation, interest filtering, saving and removing a bookmark, opening the Plan tab, and logout from Profile.


## UI-02 Place discovery and trip planning

- Interest results provide a Back action that returns travelers to their previous Home scroll position. Explore, Plan, Saved, and Profile provide Back actions to Home, which Android system back also supports.
- Plan groups interests, duration, LKR budget, travellers, and transport in separate sections. Travelers can review their recommendations and return to the form with their entries retained (see UI-11).
- Acceptance checks cover a matching catalog result, a curated suggestion, Back navigation, and submitting a completed plan.

## UI-03 Explore and attraction details

- Explore Sri Lanka shows a search field and All, Nature, History, Beaches, and Wildlife filters. Search and category filters combine, and result cards show an image where available, location, category, and supplied visit duration.
- Opening a card shows the attraction image, description, location, category, estimated duration, opening hours, and indicative entry cost when available. Back returns to the filtered list.
- Travelers can save an attraction from its details and reopen or remove it through Saved (see UI-07).
- Acceptance checks cover category filtering, details from catalog data, and the save and remove flow.

## UI-04 Northern and eastern attractions

- Explore includes Nallur Kandaswamy Temple, Koneswaram Temple, Arugam Bay Beach, Kankesanthurai Beach, Delft Island, Kayts, Point Pedro Jetty, Elephant Pass, and Sangupiddy Bridge.
- Travelers can find places using common aliases and alternate spellings, including KKS Beach, Kytes, and Aanaiyiravu. Each entry includes a location, category, and short description, and uses the existing details and bookmark flows.
- Acceptance checks cover all nine MongoDB entries, repeat server startup without duplicates, preservation of existing catalog entries, and alias search in Explore.

## UI-05 Destination imagery and visitor details

- Explore shows destination-specific artwork for all nine regional attractions. Catalog results opened from Home interest shortcuts use the same illustrated cards and details page.
- Cards include a visible View details button. Details label generated artwork as an illustration and show a suggested visit length and a practical visitor note for each of the nine places. Published hours and catalog data are shown where available.
- Acceptance checks cover artwork on the card, opening details, and returning to Explore with the search intact.

## UI-06 Branded account screens

- Login and signup use the ExploreLanka palette, a Sigiriya banner, rounded form panels, and orange primary actions.
- Signup offers Back to login. Both screens offer password visibility controls, autofill hints, and visible validation and connectivity errors.

## UI-07 Account bookmarks

- Saved includes catalog attractions and featured destinations. A confirmed save or removal persists on the traveler’s account across app restarts and sign-ins. Each traveler sees their own bookmarks. After a restart, the app restores a valid session as described in AUTH-01.
- Saved shows loading and retry states. A failed write reports the error and keeps the last confirmed bookmark state. A bookmark for a catalog entry that is no longer available can be removed.
- Acceptance checks cover a save followed by app restart and session restoration, removal, account isolation, and request failures.

## UI-08 Editable traveler profile

- Profile shows and edits the account’s full name, phone number, and email. Travelers can optionally change their password and confirm the new value. Changing email or password requires the current password.
- A successful save updates the displayed account details. The updated email and password apply at the next login. The signed-in traveler can continue using the app or log out from Profile.
- Acceptance checks cover contact edits, normalized email and phone, duplicate email, incorrect current password, mismatched confirmation, and signing in with the updated credentials.

## AUTH-02 Password recovery

- The login screen offers Forgot password. Travelers enter their account email, paste the code they receive, and confirm a new password. A successful reset returns them to login and ends their previous sessions.
- Acceptance checks cover a generic code-request response, invalid and reused codes, matching password confirmation, and login with the new password.

## UI-09 Admission on place cards

- Destination and attraction cards show admission near the place name or location. Attraction details show the same admission label. A known fee includes its currency, confirmed free admission displays Free, and missing data displays Price not listed. Destination cards identify the specific landmark or visitor category for the displayed price.
- Acceptance checks cover paid, free, and unknown admission, including legacy catalog records with a default fee of zero.

## UI-10 Travel preferences visual refresh

- Plan Your Trip uses a dark surface, a three-segment indicator with the preferences segment highlighted, and eight emoji interest tiles. Selected interests, traveller groups, and transport options use a cream fill and orange outline. Tiles and choices wrap on narrow screens.
- Travellers can adjust their stay with minus and plus controls, enter their budget in LKR including comma-grouped amounts, and submit preferences with the orange Find recommendations button (see UI-11).
- Acceptance checks cover four interest tiles per row when space permits, visible selections, a one-day minimum, submitting a completed form, and retaining preferences when returning from recommendations.

## UI-11 Personalized recommendations and travel route

- Submitting valid preferences in Plan opens Recommended for You and requests suggestions from the attractions catalog. The dark results screen shows the selected interests, duration, and budget above attraction cards with available imagery, admission, and reasons tied to the selected interests. The results can include lesser-known attractions when the catalog supports that distinction.
- Travelers can view details, save attractions to their account, remove suggestions from the current shortlist, and regenerate suggestions without bringing back removed attractions during that visit. Loading, empty results, and request errors have visible states. Back returns to Plan with its entries retained.
- Create My Travel Route opens an ordered list of the remaining attractions. The route explains its straight-line ordering and shows the selected transport as context.
- Acceptance checks cover preferences reaching the server, diverse matching results, known fee and duration limits, removing and regenerating suggestions, saving to the account, requesting a route from the remaining stops, and returning to Plan.

## UI-12 Itinerary preview

- Creating a travel route opens Your Sri Lanka Adventure with a highlands illustration, selected duration, transport, and interests, and counts for days, attractions, and interests.
- The travel plan groups the server-ordered attractions into days, marks days without suggested stops as free, and opens either an individual day's stops or the full itinerary. Each stop links to attraction details.
- Acceptance checks cover actual preference and attraction values, free days when stops are fewer than days, day and full itinerary navigation, and Back returning to the shortlist.

## UI-13 Day-by-day itinerary

- My Itinerary opens from View Full Itinerary or a day in the preview. Scrollable day tabs show the selected day's themed, numbered timeline with suggested start times, attraction images where available, visit durations, admission, and a lunch break when the plan spans midday. Free days have an empty state.
- The daily summary shows the attraction count. View Route on Map opens a zoomable schematic for the selected day's stops with valid coordinates. Tapping a timeline attraction opens its details.
- Acceptance checks cover matching the generated stop order, switching days, opening a free day, and opening the map from a day with coordinates.

## UI-14 Route map preview

- View Route on Map opens a dark preview for the selected day, with numbered and labelled stops in the suggested order. The map displays direct distance for multiple mapped stops and offers pan, zoom, expand, and reset. The ordered list links to attraction details.
- Acceptance checks cover opening the selected day's map, visible stop labels and order, expanding and restoring the map, and returning to the itinerary.

## UI-15 Saved trips

- Travellers can save a generated itinerary from its preview. Saved opens on Trips and offers a Places section for existing bookmarks.
- Saved Trips lists account itineraries with the trip length, stop count, and preferred transport. Travellers can reopen the itinerary, its day timeline and map, or remove the saved trip. Trips remain available after signing in again.
- Acceptance checks cover saving and reopening the generated stop order and preferences, repeated saves without duplicates, removal, account isolation, and existing place bookmarks.

## ADMIN-01 Platform administration

- ExploreLanka has a separate React web dashboard. An account with the administrator role can sign in using its existing credentials and sign out. The server rejects unsigned requests and requests from ordinary traveler accounts to all administration endpoints.
- Administrators can search and filter attractions, create and edit catalog entries, and archive or restore them. Archived attractions disappear from the traveler catalog and new trip planning. Existing saved itinerary snapshots and bookings retain their recorded attraction details.
- Administrators can record manual bookings for active attractions with a guest name, email, visit date, and party size. They can search and filter bookings and set their status to pending, confirmed, completed, or cancelled. New bookings start pending. Traveler checkout, payments, availability, and notifications are outside this scope.
- Acceptance checks cover role enforcement, valid and invalid attraction changes, persistent archive and restore across restarts, booking creation and status changes, rejection of invalid bookings, and loading, empty, and error states.

## MOB-01 Android and iOS support

- ExploreLanka runs on Android and iOS from the same Flutter app. The iOS runner displays the ExploreLanka name and uses the same account, catalog, itinerary, and saved-content flows as Android. Persistent sign-in follows AUTH-01 on both platforms.
- The iOS simulator can use a local backend during debug development. An iPhone can use a reachable API URL. Profile and release authentication require HTTPS.
- Acceptance checks cover building the iOS simulator app, launching to the branded startup and login screens, and using the same authentication and session recovery flows. Existing Android behavior remains supported.
