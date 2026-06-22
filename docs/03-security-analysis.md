# Security Analysis — Chargix

> **How to use this file:** Anywhere you see `[[FILL: ...]]`, paste the real value
> (mostly from reading your `firestore.rules`). Do not claim any tool was run that
> you did not run. Delete this note before submitting.

---

## 1. Overview

Chargix handles user accounts, vehicle data, charging-station bookings, and
location data. This document analyzes the security posture of the application
against the **OWASP Top 10:2025** standard and describes the concrete measures
implemented to mitigate each relevant risk.

Chargix is built on Firebase (Authentication, Cloud Firestore, Cloud Messaging),
which provides a managed, hardened backend. This means several critical security
properties — transport encryption, encryption at rest, and infrastructure
patching — are provided and enforced at the platform layer rather than
hand-implemented, which is the recommended secure-by-default architecture.

---

## 2. Threat Model — OWASP Top 10:2025

The OWASP Top 10 is the industry-standard awareness document for the most critical
web and application security risks. The 2025 edition is the current release. The
four categories most relevant to Chargix's architecture are analyzed below.

### A01:2025 — Broken Access Control

**Risk:** Users accessing or modifying data they are not authorized to (e.g. one
driver reading another driver's bookings, or a driver editing a station's data).

**Mitigation in Chargix:**
- **Cloud Firestore Security Rules** are deployed and enforce access control on the
  server side, independent of the client. A user can only read/write documents they
  own or are authorized for.
- Driver and operator roles are separated, so station-management operations are not
  available to driver accounts and vice versa.
- `[[FILL: summarize 2–3 of your actual rules, e.g. "bookings can only be read by the
  driver who created them or the station operator who owns the station"]]`

### A02:2025 — Security Misconfiguration

**Risk:** Insecure defaults, overly permissive rules, or exposed configuration.
(This is the biggest mover in the 2025 edition, rising from #5 to #2.)

**Mitigation in Chargix:**
- Firestore does **not** run in open/test mode. Default-deny rules are in place, so
  any access not explicitly allowed is rejected.
- No secrets or API keys are hardcoded in the client source in an exposed way; the
  Google Maps/Places key is restricted `[[FILL: confirm key restriction — you fixed
  an Android app-restriction config earlier]]`.
- Debug-only and deferred features are guarded and not active in normal runtime.

### A05:2025 — Injection

**Risk:** Untrusted input being interpreted as a command or query.

**Mitigation in Chargix:**
- Chargix uses the **Firestore SDK**, which uses parameterized, typed queries
  rather than string-concatenated query languages — this structurally prevents the
  classic injection vectors (there is no SQL string to inject into).
- **Input validation** is applied on user-entered fields (e.g. license plate,
  profile fields, booking inputs) before they are written.

### A07:2025 — Authentication Failures

**Risk:** Weak authentication, account takeover, poor session handling.

**Mitigation in Chargix:**
- Authentication is handled by **Firebase Authentication**, a managed identity
  provider — not custom auth code (rolling your own auth is an OWASP anti-pattern).
- Drivers authenticate via **phone-number OTP**; station operators via
  **email/password**. Sessions and tokens are issued and validated by Firebase.
- Session tokens are managed securely by the Firebase SDK, not stored manually in
  plaintext.

---

## 3. Data Protection & Encryption

Chargix protects data at three layers:

1. **In transit — encrypted (TLS/HTTPS).** All communication between the app and
   Firebase/Google services runs over TLS, enforced automatically by the Firebase
   SDK. No data is sent over plaintext HTTP.
2. **At rest — encrypted (AES-256).** Cloud Firestore encrypts all stored data at
   rest by default on Google Cloud infrastructure.
3. **Local device storage.** Sensitive session state is managed by the Firebase
   SDK. Non-sensitive flags (e.g. onboarding-complete, remember-me preference) are
   the only values stored locally.
   `[[FILL: if you add flutter_secure_storage for any sensitive local value, note it
   here; otherwise state that no sensitive data is stored in plaintext locally]]`

**On custom encryption:** Chargix deliberately relies on platform-level encryption
rather than implementing application-layer cryptography. Hand-rolled cryptography is
explicitly discouraged by security best practice, as it tends to introduce more risk
than it removes. Delegating encryption to the audited Firebase/Google Cloud layer is
the more secure architectural choice.

---

## 4. API & Network Security

- **Token-based authentication** — every authenticated request carries a Firebase
  ID token, validated server-side.
- **HTTPS only** — all API and Google Places traffic uses HTTPS.
- **API key restriction** — the Google Maps/Places API key is restricted to the
  app `[[FILL: confirm the restriction type now in place]]`.
- **Least privilege** — Firestore rules grant the minimum access each role needs.

---

## 5. Security Tools & Verification

> **Be honest here.** Only list what you actually did.

- **Firestore Security Rules** were written, deployed, and tested against the app's
  access patterns. `[[FILL: mention if you used the Firebase console Rules Playground
  to test them — that is a legitimate, real verification step]]`
- **Manual review** of authentication flows and input validation.
- *Optional / future work:* automated mobile-app security scanning with tools such
  as MobSF, and dynamic analysis with OWASP ZAP, are recommended as next steps but
  were outside the scope of this project's timeframe.

---

## 6. Summary

Chargix follows a secure-by-default architecture: authentication, transport
encryption, and at-rest encryption are delegated to a hardened managed platform,
while application-specific access control is enforced through deployed Firestore
Security Rules mapped to the OWASP Top 10:2025 categories most relevant to the app
(A01 Broken Access Control, A02 Security Misconfiguration, A05 Injection, and A07
Authentication Failures).
