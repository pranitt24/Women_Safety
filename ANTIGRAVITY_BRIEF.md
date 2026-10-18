# Brief for Antigravity: make Sakhi Safety real

Paste this whole file as the first prompt, with the project folder open. Work in the order below.
Run `flutter analyze` and `flutter run` on a real Android phone after each step, and fix errors before moving on.

## Context
Women's safety app (Flutter, Android first) to be shown to a police crime branch tomorrow afternoon.
The current code in `lib/` is a UI prototype written without a compiler: expect compile errors, fix them first.
The visual and interaction reference is the published HTML prototype (look and flow of SOS, map, auto-detect, police console).
Design tokens: accent teal #0B7A6A, SOS red #C8202F, cool grey-green background #E9EEEC, dark mode supported.
Fonts: Bricolage Grotesque (headings), Instrument Sans (body), JetBrains Mono (small labels), via `google_fonts`.

## Hard rules (do not break)
1. **No offender data, names, photos or addresses anywhere.** The heat map shows zone-level aggregates only.
2. All data in the demo is **synthetic or user-reported**. Label the map "Demo data" in the UI.
3. No real personal data in a free-tier cloud project other than the team's own test accounts.
4. Every distress alert has a 10 second cancel countdown before sending (already built, keep it).

## Step 1: Make it compile and run
- `flutter pub get`, fix API mismatches (flutter_blue_plus, flutter_ble_peripheral, sensors_plus, connectivity_plus).
- Add Android permissions from README.md. Confirm SOS countdown, map and auto-detect screens work.

## Step 2: Real map with hotspots
- Replace the custom-painted grid in `screens/map_screen.dart` with `flutter_map` + `latlong2` using OpenStreetMap tiles
  (set `userAgentPackageName`; OSM tiles are fine for a demo, note it in the code for later swap to a paid tile provider).
- Put the map centre in one constant `kCityCenter` (ask me for the city; default Mumbai 19.0760, 72.8777).
- Real geolocation: `geolocator` for the user's live position, blue dot on the map, "locate me" button.
- Hotspots: a grid of hexagon or square polygons (about 150 m) over the visible area, coloured by risk with
  transparency (same red scale as the prototype). Risk is computed from incident points, not hard-coded:
  `risk(cell, hour) = sum over incidents within 300 m of weight * time_decay(hour)`.
- Incident points come from the backend (Step 3). Until then seed ~200 synthetic points clustered around 4 hotspots near `kCityCenter`.
- Keep: time-of-night slider (6 PM to 2 AM), layers for CCTV, street lights, police booths (synthetic markers),
  tap a zone for a bottom sheet (reports in 90 days, busiest hour, lighting, advice text).
- "Report an incident" button: user long-presses a spot on the map, picks a category (harassment, stalking,
  poor lighting, unsafe area), no free text with names, submits an anonymous report. It appears in the heat map after a refresh.

## Step 3: Backend (Firebase, region asia-south1 Mumbai)
Use FlutterFire (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`).
- Auth: phone number OTP (Firebase test numbers are fine for the demo).
- Collections:
  - `users/{uid}`: name, fcmToken, trustedContacts[] (name, phone, uid if they have the app)
  - `alerts/{id}`: uid, name, zoneLat/zoneLng (rounded to ~100 m), reason, via ("internet" | "ble"), battery,
    status (new|ack|dispatched|resolved|cancelled), createdAt, liveLocation subcollection
  - `incidents/{id}`: lat, lng (rounded), category, hourBucket, createdAt, source ("user" | "police" | "synthetic")
  - `zonesPublished/{cellId}`: published boolean (police-controlled)
- Replace the stub in `services/backend.dart`: `sendAlert` writes the alert; a Cloud Function (or a simple trigger)
  sends FCM push to trusted contacts who have the app. Also open a pre-filled `sms:` / WhatsApp link as a fallback for
  contacts without the app (the user taps send; silent SMS needs a paid gateway and India DLT registration, out of scope).
- Live location: while an alert is active, write the position to `alerts/{id}/liveLocation` every 10 s.
  Contacts open the alert and see a moving pin on a flutter_map.
- Status sync: the citizen app listens to its alert document, so police "Acknowledge / Dispatch / Resolve" shows on the phone live.
- Firestore security rules: users read/write only their own doc; contacts can read alerts that name them;
  only users with a `police` custom claim can update alert status and `zonesPublished`; incidents are write-only for citizens.

## Step 4: Police console (Flutter web, same repo, `lib/police/`)
- Build for web (`flutter build web`), sign-in with an email account that has the `police` claim.
- Screens: live alerts list with Acknowledge/Dispatch/Resolve and a map with the live pin; hotspot table with
  a "publish to public" switch per zone; KPI tiles; reports by hour chart; "Import incidents (CSV)" with columns
  lat,lng,category,hour so the police can load aggregate data themselves.
- Match the HTML prototype's console layout.

## Step 5: Real features behind the toggles
- Network loss: already wired through connectivity_plus. Make it require a second signal before alerting (keep the scoring).
- Impact/fall: accelerometer spike then 3 s of stillness (use `sensors_plus`).
- Route deviation: when Safe journey is on, user picks a destination; compare position to the straight-line or routed corridor
  (use OSRM public demo server or a simple 150 m corridor around the line for the demo).
- Long stop: stationary more than 6 minutes outside saved places.
- Missed check-in: local notification "Reached safely?" at the ETA, countdown if unanswered.
- Foreground service (`flutter_foreground_task`) so SOS, BLE relay and detection keep running with the screen off.
- BLE relay: test on 3 phones. Phone A airplane mode + Bluetooth on sends SOS, phone B with internet uploads it to Firestore.
  Show a "relayed by nearby phone" event in the console. Add rate limiting (max 1 relay per alert id) and a TTL of 3 hops.

## Step 6: UI polish (last, only if time remains)
- Match the prototype: large SOS button with hold ring, calm cards, red full-screen countdown, green check steps.
- Add haptics on countdown start and send. Add a fake-call screen and a discreet "dark" mode.
- Empty states and loading states for every screen. No placeholder text.

## Acceptance checklist for tomorrow's demo
- [ ] Real OSM map centred on the city with live blue dot and red hotspot polygons
- [ ] Time slider changes the hotspots
- [ ] Reporting an incident adds a point and updates the heat map
- [ ] SOS (hold, countdown, send) writes an alert, push arrives on a second phone, police console shows it within 3 s
- [ ] Police "Acknowledge" shows on the citizen phone
- [ ] Live location pin moves on the second phone
- [ ] Airplane-mode SOS reaches the console via a nearby phone over BLE
- [ ] Auto-detect: network loss + impact triggers the countdown
- [ ] Unpublishing a zone in the console greys it out on the citizen map
