# Performance Analysis — Chargix

> **How to use this file:** This report describes the performance-oriented design
> decisions actually made in Chargix. It deliberately contains **no invented
> benchmark numbers.** If you measure real values in Flutter DevTools (profile mode),
> add them to §4 in the marked spot. Delete this note before submitting.

---

## 1. Overview

This document analyzes Chargix from a performance perspective: how the app is built
to stay responsive, where the main performance-sensitive paths are, and which
techniques are used to keep the UI smooth and data access efficient. Chargix runs on
Flutter, which compiles to native ARM code and renders its own UI, giving a strong
performance baseline before any app-specific optimization.

---

## 2. Performance-sensitive areas

The areas where performance matters most in Chargix are:

- **The map screen** — rendering the map, placing markers for partner and external
  stations, and animating the camera.
- **Real-time lists** — the operator dashboard and reservation lists, which update
  live as bookings change.
- **App startup** — getting from launch to the first usable screen, including the
  authentication gate.

These are the paths that were kept in mind during implementation.

---

## 3. Optimization techniques applied

### 3.1 Real-time data via streams (not polling)

The operator dashboard and booking screens use **Firestore streams**, so the UI
receives updates only when data actually changes, rather than repeatedly polling the
database. This reduces unnecessary network calls and keeps the displayed data current
without manual refresh.

### 3.2 Single-document streams for detail screens

The booking-details screen subscribes to a **single-document stream** (`watchBooking`)
rather than re-reading the whole collection, so a detail view stays live while
fetching the minimum necessary data.

### 3.3 Scoped rebuilds with ChangeNotifier

State is managed with `ChangeNotifier`, and screens listen to notifiers so that only
the widgets depending on changed state rebuild — avoiding full-screen rebuilds on
every state change.

### 3.4 Efficient, server-side-filtered queries

Where possible, filtering and access control happen at the Firestore layer (via
queries and security rules) rather than fetching large datasets and filtering on the
device. This reduces the amount of data transferred to the client.

### 3.5 Transaction-based booking

Slot booking runs inside a **Firestore transaction**, which both guarantees
correctness under concurrent access and avoids the overhead and risk of multiple
separate read/write round-trips for a single booking action.

### 3.6 Time-based background work kept lightweight

Auto-completion of sessions and no-show detection use a periodic check (every ~60
seconds) rather than a constant tight loop, keeping background CPU use minimal.

---

## 4. Measured metrics (optional — add real numbers only)

> `[[FILL (optional): If you run `flutter run --profile` and open Flutter DevTools,
> capture and paste real values here:
>   - App startup time (from the profile-mode console / DevTools)
>   - Frame rendering — share of frames under 16ms (60fps) from the Performance tab
>   - Memory footprint during normal use, from the Memory tab
> Attach the DevTools screenshots. If you did NOT measure, delete this section
> entirely rather than estimating — do not invent numbers.]]`

**How to measure (if you choose to):**
1. Run `flutter run --profile` on a real device (profile mode — never measure in debug).
2. Open the DevTools URL printed in the console.
3. **Performance tab** — interact with the app (open the map, scroll bookings) and
   read the frame chart; green frames are under the 16ms 60fps budget.
4. **Memory tab** — note the memory footprint during normal use.
5. Screenshot each for the report.

---

## 5. Tools

- **Flutter DevTools** — the official profiling suite (Performance and Memory tabs)
  for frame timing and memory analysis.
- **Profile mode** (`flutter run --profile`) — the correct build mode for performance
  measurement; debug-mode numbers are not representative.
- **Firebase** usage patterns (streams, transactions, server-side rules) as described
  in §3.

---

## 6. Summary

Chargix is built on a performance-friendly foundation (Flutter compiled to native
code) and applies sensible, real optimizations on the data layer: stream-based
real-time updates instead of polling, single-document streams for detail views,
scoped rebuilds via ChangeNotifier, server-side filtering, transaction-based booking,
and lightweight periodic background checks. Detailed quantitative profiling with
Flutter DevTools is identified as the natural next step for formal benchmarking.
