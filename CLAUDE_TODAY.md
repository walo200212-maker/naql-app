# Today's Session — 2026-06-10

Continuation of the "app doesn't work on any phone" debugging pass. Six issues
were diagnosed; the first three were Firebase/Google Cloud Console
configuration fixes (Firestore security rules, Storage bucket provisioning,
Google Sign-In SHA-1 fingerprint registration). The remaining three were code
fixes:

## 4. Phone OTP errors on Android
**Files**: `lib/data/services/auth_service.dart`, `lib/presentation/providers/auth_provider.dart`
**Problem**: `FirebaseAuth.verifyPhoneNumber()` returns as soon as its
listeners are registered — *not* once an SMS is sent. `AuthProvider.sendOtp`
was awaiting that future directly, so `login_screen.dart` navigated to the OTP
screen immediately, before `_verificationId` was ever set. Any code the user
typed was rejected as "incorrect" because `verifyOtp` bailed out early
(`_verificationId == null`).
**Fix**:
- `AuthService.sendOtp` gained an `onAutoVerified` callback, fired from
  `verificationCompleted` (Android SMS Retriever instant verification).
- `AuthProvider.sendOtp` now wraps the callbacks in a `Completer` and awaits
  it (with a 60s timeout fallback), so it only returns once `onCodeSent`,
  `onError`, or `onAutoVerified` has actually fired.
- New `_autoVerified` flag: if Android silently signs the user in via SMS
  Retriever before they finish typing, `verifyOtp` short-circuits to `true`
  (the user is already authenticated — any code they enter is accepted).

## 5. Auth session not persisting across app restarts
**File**: `lib/presentation/screens/splash/splash_screen.dart`
**Problem**: The splash animation runs for ~1.7s, then `onAnimationComplete`
checked `auth.status` exactly once. On cold start, Firebase Auth's
`authStateChanges()` (plus the Firestore profile fetch in
`AuthProvider.init()`) can take longer than that, so `status` was still
`AuthStatus.unknown` → routed to onboarding even for a logged-in user.
**Fix**: `SplashScreen` is now a `StatefulWidget` that waits for **both** the
animation to finish **and** `auth.status != AuthStatus.unknown` before
navigating, with a 5s timeout fallback in case auth state never resolves
(e.g. fully offline cold start).

## 6. Google Maps not loading on client home (mobile)
**File**: `lib/presentation/screens/client/client_home_screen.dart`
**Problem**: `GoogleMap(myLocationEnabled: true, ...)` was hardcoded, but
location permission is requested asynchronously in `initState()`. On first
launch the map widget builds with `myLocationEnabled: true` *before*
ACCESS_FINE_LOCATION is granted — Android throws a `PlatformException`
("Permission Denial") that breaks the map view.
**Fix**: Added `_locationGranted` state (default `false`). `_initLocation()`
now calls `Geolocator.checkPermission()` first, requests if needed, and only
sets `_locationGranted = true` once permission is actually granted.
`myLocationEnabled` is now bound to `_locationGranted` instead of hardcoded
`true`.

## Status
All 6 todo items from this debugging pass are complete. 4 files modified,
uncommitted (`auth_service.dart`, `auth_provider.dart`,
`client_home_screen.dart`, `splash_screen.dart`). `flutter analyze` clean on
all of them.
