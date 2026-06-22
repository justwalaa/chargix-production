# Code Quality & Testing — Chargix

> **How to use this file:** Anywhere you see `[[FILL: ...]]`, paste the real value
> from the Claude Code command (see the end of this document). Do not invent numbers.
> Delete this note before submitting.

---

## 1. Code Quality Approach

Chargix is built on a layered architecture that separates concerns so that UI,
business logic, and data access can each evolve and be tested independently.

### 1.1 Architecture

Chargix uses a **repository pattern with `ChangeNotifier` state management**
(via the `provider` package). The layers are:

- **Presentation layer** — Flutter screens and widgets. Screens listen to
  notifiers and rebuild only when relevant state changes.
- **State layer** — `ChangeNotifier` classes hold UI state and expose actions.
  They never talk to Firebase directly; they call repositories.
- **Repository layer** — repositories own all data access (Firestore reads/writes,
  Auth, Google Places calls). They expose clean methods and streams to the state
  layer, hiding the data source details.
- **Model layer** — plain Dart model classes that map Firestore documents to typed
  objects, keeping the rest of the app free of raw `Map<String, dynamic>` access.

This separation means a screen does not know whether data comes from Firestore or
the Google Places API, and the data source can change without touching the UI.

### 1.2 Why `ChangeNotifier` (and not Bloc/Riverpod)

`ChangeNotifier` with `provider` was chosen deliberately for a solo-developed
project of this scope: it is the Flutter team's first-party recommendation for
small-to-medium apps, has the lowest boilerplate, and keeps the learning surface
small so development time goes into features, not framework ceremony. The
repository pattern layered on top gives most of the testability benefits that a
heavier solution like Bloc would provide, without the added complexity.

### 1.3 Design principles applied

- **Separation of concerns** — UI, state, and data access are isolated (above).
- **Single responsibility** — each repository handles one domain (auth, bookings,
  stations, etc.); each notifier manages one screen/feature's state.
- **Dependency direction** — UI depends on state, state depends on repositories,
  repositories depend on data sources. Dependencies point inward; nothing reaches
  back up.
- **DRY** — shared widgets (e.g. the logout dialog, status badges, booking cards)
  are reused across driver and station sides rather than duplicated.

---

## 2. Linting & Static Analysis

Chargix uses Dart's built-in static analysis to enforce consistent style and catch
problems before runtime.

- **`flutter_lints`** — the official lint ruleset, enabled via `analysis_options.yaml`.
- **`dart analyze`** — runs the analyzer across the whole codebase.
- **`dart format`** — enforces consistent formatting.

**Analyzer result:**
`[[FILL: paste the output of `flutter analyze` — e.g. "No issues found" or the issue count]]`

**Formatting result:**
`[[FILL: paste the result of `dart format` — how many files are already correctly formatted]]`

> Note on known analyzer messages: any remaining info-level messages are
> pre-existing and harmless (e.g. an HTML-in-doc-comment in a test file, and
> two intentional `if (false)` dead-code blocks guarding the deferred Google
> Sign-In feature). These are documented and do not affect runtime behavior.

---

## 3. Testing Strategy

Chargix is tested at three levels, following the standard Flutter testing pyramid:
many fast unit tests at the base, widget tests in the middle, and integration
tests at the top.

### 3.1 Unit tests — business logic

Unit tests cover the logic that does not depend on the UI: repository methods,
model mapping (Firestore document → Dart model and back), validation rules, and
state transitions inside the notifiers.

### 3.2 Widget tests — UI

Widget tests verify that individual screens and components render correctly and
respond to interaction — for example that a booking card shows the correct status,
or that a required field blocks submission when empty.

### 3.3 Integration tests — full flows

Integration tests exercise end-to-end flows across multiple screens (for example,
the booking flow from selecting a station through to a confirmed reservation).

### 3.4 Test suite summary

- **Total test files:** `[[FILL: count of test files — you have ~8]]`
- **Total test cases:** `[[FILL: total test count — you have ~40]]`
- **Pass rate:** `[[FILL: from `flutter test` — e.g. "40/40 passing"]]`
- **Line coverage:** `[[FILL: % from `flutter test --coverage` + lcov]]`

### 3.5 Tools

- **`flutter_test`** — the core test framework (unit + widget tests).
- **`integration_test`** — for full-flow tests.
- **Mockito / mocktail** — `[[FILL: confirm which mocking package is in pubspec, if any]]`
  for mocking Firebase/Firestore so tests run without hitting live services.

---

## 4. Maintainability

- Consistent naming conventions across files and classes.
- Dead/unused files were identified in a codebase audit and removed to keep the
  project clean.
- Shared UI components are centralized for reuse.
- Models provide a typed boundary so Firestore schema changes surface as compile
  errors rather than silent runtime bugs.

---

## 5. How to fill the blanks (run this in Claude Code)

> Run each command and paste the **real** output back. Do not estimate any number.
>
> 1. `flutter analyze` → for §2 (analyzer result)
> 2. `dart format --output=none --set-exit-if-changed .` → for §2 (formatting result)
> 3. `flutter test` → for §3.4 (pass/fail count)
> 4. `flutter test --coverage` then compute line coverage % from `coverage/lcov.info` → for §3.4
> 5. Count files in the `test/` directory and total test cases → for §3.4
> 6. Read `pubspec.yaml` and confirm the mocking package (mockito/mocktail) → for §3.5
