# Chargix ⚡

A cross-platform mobile app for booking electric vehicle (EV) charging
stations, built end to end with Flutter and Firebase.

Chargix lets drivers find nearby charging stations on a live map, book a
session, check in via QR code, and have sessions auto-complete — while
station owners manage their stations from a separate dashboard.

## ✨ Features

- **Live station map** — find nearby stations using Google Places API
  (Nearby Search), with distance-based sorting and filter chips
- **Full booking lifecycle** — QR check-in, session auto-completion,
  and no-show handling
- **Two account types** — phone-OTP login for drivers, email/password
  for station owners, with separate flows
- **Station statistics** — usage insights for station owners
- **Secured backend** — Firestore security rules mapped to OWASP Top 10
- **Tested** — 143 passing automated tests covering core booking logic

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **Backend:** Firebase — Firestore, Authentication, Security Rules
- **Maps & Location:** Google Maps SDK, Google Places API (Nearby Search)
- **Testing:** Flutter test suite (143 tests)

## 📱 Screenshots

| Map & Search | Booking | Station Dashboard |
|---|---|---|
| ![map](screenshots/map.png) | ![booking](screenshots/booking.png) | ![dashboard](screenshots/dashboard.png) |

## 🚀 Getting Started

```bash
# Clone the repo
git clone https://github.com/justwalaa/chargix.git
cd chargix

# Install dependencies
flutter pub get

# Run the app
flutter run
```

> Requires a Firebase project and a Google Maps API key.
> Add your own `google-services.json` / API key before running.

## 🧪 Running Tests

```bash
flutter test
```

## �doublequote 👤 Author

**Walaa Marai** — Software Engineering, JUST (2026)
[LinkedIn](https://www.linkedin.com/in/walaa-marai) ·
[GitHub](https://github.com/justwalaa)
