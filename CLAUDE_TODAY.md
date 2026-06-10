# Today's Session — 2026-06-09

## 1. Sign-in navigation fix
**Problem**: After signing in (Google, email, phone) the app didn't navigate to the next screen.
**Root cause**: `refreshListenable: authProvider` in GoRouter caused every `notifyListeners()` to retrigger route evaluation, racing with manual `context.go()` calls.
**Fix**: Removed `refreshListenable` entirely from `GoRouter` in `app_router.dart`.
Also added try-catch around `loadCurrentUserProfile()` in `login_screen.dart`, `otp_screen.dart`, `password_screen.dart` so Firestore errors don't silently swallow navigation.

## 2. Google Maps web billing wall
**Problem**: Web build showed "This page didn't load Google Maps correctly" — requires credit card.
**Fix**: Added `kIsWeb` check in `client_home_screen.dart`. Web shows `_WebMapPlaceholder` (dark container with map icon + Arabic text). Mobile Google Maps untouched.

## 3. Moroccan address autocomplete
**Files**: `lib/data/services/geocoding_service.dart` (new), `lib/presentation/screens/client/post_job_screen.dart`
**What**: Free OpenStreetMap Nominatim API for real Moroccan address suggestions in pickup/dropoff fields.
- `GeocodingService.searchMorocco(query)` — `countrycodes=ma`, `accept-language: ar,fr`
- 600ms debounce, 8s timeout, max 5 results
- `_LocationField` converted from `StatelessWidget` → `StatefulWidget` with inline dropdown
- Tapping suggestion fills field + stores `LocationData(address, lat, lng)` in `JobProvider`
- No API key, no billing ever

## 4. Animated splash screen with real logo
**Files**: `lib/presentation/splash/wasl_app_splash_screen.dart` (new), `lib/presentation/screens/splash/splash_screen.dart` (rewritten)
- Replaced old orange-box-with-truck-icon splash with actual `waslapp_logoo.png`
- Animation: logo slides in from left (easeOutCubic 800ms) + elastic bounce overshoot
- `onAnimationComplete` callback fires after animation → navigates based on auth state
- `SplashScreen` is now a thin wrapper that passes navigation logic as callback

## 5. Logo on login screen
**File**: `lib/presentation/screens/auth/login_screen.dart`
- Replaced orange container + truck icon + "وصل" text with `Image.asset('assets/images/waslapp_logoo.png')`
- Kept fade+scale animation

## 6. `_PhotoPickerTile` performance fix
**File**: `lib/presentation/screens/driver/driver_registration_screen.dart`
**Problem**: `FutureBuilder(future: image!.readAsBytes(), ...)` was called directly in `build()`. Every `setState` (e.g. moving the price slider) created a new Future, causing all picked images to re-read from disk and flash blank on every frame.
**Fix**: Converted `_PhotoPickerTile` from `StatelessWidget` to `StatefulWidget`. Bytes are read once in `initState()` and cached in `_bytesFuture`. `didUpdateWidget` only re-reads when the `XFile` reference actually changes (new image picked).

## Asset note
- Logo file: `assets/images/waslapp_logoo.png` (transparent PNG, note double-o)
- Original JPEG kept at `assets/images/waslapp_logo.jpeg`
- After adding new assets always run `flutter clean && flutter pub get` before running — web build caches asset manifest and won't pick up new files otherwise
