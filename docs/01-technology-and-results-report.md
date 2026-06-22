# Technology & Results Report — Chargix



---

## 1. System Overview

**Chargix** is a mobile application that connects electric-vehicle (EV) drivers with
charging stations, allowing drivers to discover stations on a map, book charging
slots, and check in via QR code, while station operators manage their stations,
availability, and reservations.

### 1.1 Use case

EV adoption is growing faster than charging infrastructure is organized. Drivers
often cannot tell in advance whether a station is available, and operators have no
simple tool to manage bookings. Chargix addresses both sides: it gives drivers a
reservation-based system so they arrive at a station that is confirmed available, and
gives operators a dashboard to manage their stations and bookings.

### 1.2 Target users

- **EV drivers** — discover nearby charging stations, view details and ratings, book
  time-window slots, and check in on arrival.
- **Station operators** — manage their station's profile, availability/slots,
  pricing, and incoming reservations, and view usage statistics.

---

## 2. Architecture

Chargix uses a layered client architecture with a managed Firebase backend.

### 2.1 Layers

- **Frontend (Flutter)** — a single cross-platform codebase serving both the driver
  and the station-operator experiences.
- **State management** — Flutter's built-in `ChangeNotifier`, organized under a
  repository pattern so the UI never accesses data sources directly (no third-party
  state-management package is used).
- **Backend (Firebase)** — Authentication, Cloud Firestore (database), and Cloud
  Messaging (push notifications), all managed services.
- **External services** — Google Maps SDK (map rendering) and Google Places API
  (external/non-partner station data and ratings).

### 2.2 Architecture diagram

`[[FILL: insert your architecture diagram here. Build it in draw.io (app.diagrams.net)
or export your existing Mermaid diagram from mermaid.live. Three layers:
Flutter app (driver + station UI) → Firebase (Auth, Firestore, FCM) →
External APIs (Google Maps SDK, Google Places). Export as PNG.]]`

### 2.3 Data flow

A screen reads or writes data only through its state notifier, which calls a
repository. The repository talks to Firestore (or the Google Places API for external
stations) and returns typed model objects or streams. Real-time data (such as
incoming bookings on the operator dashboard) uses Firestore streams, so the UI
updates live without manual refresh.

---

## 3. Technology Stack

| Layer | Technology |
|---|---|
| Frontend framework | Flutter 3.41.8 |
| Language | Dart 3.11.5 |
| State management | Built-in `ChangeNotifier` + repository pattern (no third-party state package) |
| Authentication | Firebase Authentication (Phone OTP for drivers, email/password for operators) |
| Database | Cloud Firestore |
| Push notifications | Firebase Cloud Messaging (FCM) + `flutter_local_notifications` |
| Maps | Google Maps SDK (`google_maps_flutter`) |
| Location | `geolocator` |
| External station data | Google Places API (via `http`) |
| QR check-in | `qr_flutter` (display) + `mobile_scanner` (scan) |
| Typography | `google_fonts` (Manrope) |
| Icons / animation | `phosphor_flutter`, `flutter_animate` |
| Other | `url_launcher`, `share_plus`, `crypto`, `shared_preferences` |

**Resolved dependency versions** (from `pubspec.lock`): firebase_core 3.15.2,
firebase_auth 5.7.0, cloud_firestore 5.6.12, firebase_messaging 15.2.10,
flutter_local_notifications 17.2.4, google_maps_flutter 2.17.0, geolocator 13.0.4,
http 1.6.0, mobile_scanner 6.0.11, qr_flutter 4.1.0, shared_preferences 2.5.5,
url_launcher 6.3.2, share_plus 10.1.4, crypto 3.0.7, google_fonts 6.3.3,
flutter_animate 4.5.2, phosphor_flutter 2.1.0.

> Note: `google_sign_in` (6.3.0) is present in dependencies but the Google Sign-In
> flow is currently deferred (guarded behind disabled code), so it is not an active
> runtime feature.

> **Confirm:** how `ChangeNotifier` is exposed to the widget tree — e.g. via
> `ListenableBuilder` / `AnimatedBuilder`, or `addListener` in `initState`. State
> this one detail accurately in case you are asked.

---

## 4. Key Features

- **Map-based station discovery** — a dual-source map showing both partner stations
  (from Firestore) and external stations (from Google Places), with custom markers.
- **Booking system** — drivers book time-window slots at a station.
- **QR check-in** — operators show a QR code that validates the driver's booking on
  arrival.
- **Real-time operator dashboard** — incoming reservations update live via Firestore
  streams.
- **Authentication** — separate, role-appropriate sign-in for drivers and operators.
- **Verified driver badges** — `[[FILL: brief description of how verification works]]`
- **Push notifications** — booking and session updates delivered via FCM.
- **Station statistics** — usage metrics computed from real booking data.

---

## 5. Implementation Notes

`[[FILL (optional): 1–2 short paragraphs on any notable engineering challenges you
solved — e.g. diagnosing the Google API key Android-restriction issue that was
silently blocking Places calls, or the authentication routing fix. These make great
"what did you learn" defense answers.]]`

---

## 6. Results

> Complete this section last, once the final UI and APK are ready.

### 6.1 Screenshots

`[[FILL: insert final screenshots — Home/discovery map, station detail with rating,
booking flow, operator dashboard, statistics screen, splash. Use the redesigned
light-theme UI.]]`

### 6.2 Functional results

`[[FILL: short summary of what works end-to-end — e.g. "drivers can register,
add a vehicle, discover and book a station, and check in via QR; operators can
manage stations and view live bookings and statistics."]]`

### 6.3 Performance (optional — only if measured)

`[[FILL: if you captured real numbers in Flutter DevTools (profile mode), put them
here — startup time, frame rendering, memory. If you did NOT measure, delete this
section rather than inventing numbers. See the separate performance report.]]`

---

## 7. Conclusion

Chargix demonstrates a complete, two-sided EV charging booking system built on a
clean layered Flutter architecture and a managed Firebase backend, integrating live
location services and real-time data. The architecture keeps UI, state, and data
access separated, which supports testability and future extension.
