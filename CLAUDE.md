# WaslApp (وصل) — CLAUDE.md

## What this app is
Truck moving marketplace for Morocco. Clients post moving jobs, drivers bid on them. Think Uber but for trucks/moving.

## Tech stack
- **Flutter** (web + mobile) — `sdk: ^3.11.0`
- **Firebase**: Auth, Firestore, Storage, Messaging — project ID: `naql-bc9e3`
- **GoRouter** `^14.2.7` — navigation
- **Provider** `^6.1.2` — state management
- **google_fonts**, **flutter_animate** — UI
- **http** `^1.2.2` — Nominatim geocoding
- **google_maps_flutter** — mobile only
- **flutter_map** `^7.0.2` + **latlong2** `^0.9.1` — web maps (OSM/CARTO, no API key needed)

## Running the app
```
flutter pub get
flutter run -d chrome        # web
flutter run                  # mobile (pick device)
```
After adding new assets always run `flutter clean && flutter pub get` first.
Hot reload with `r`, full restart with `R` in terminal.

## Project structure
```
lib/
  app_router.dart              # GoRouter config — NO refreshListenable
  main.dart
  core/
    constants/
      app_routes.dart          # All route strings
      app_constants.dart       # Firestore collections, truck types, cities
    theme/
      app_colors.dart          # #0F0F0F bg, #F97316 orange primary, #EDE8DF cream
      app_text_styles.dart
      app_theme.dart
  data/
    models/                    # user_model, driver_model, job_model, offer_model ...
    services/
      auth_service.dart
      firestore_service.dart
      storage_service.dart
      geocoding_service.dart   # Nominatim OpenStreetMap — free, no billing
  presentation/
    providers/
      auth_provider.dart       # AuthStatus: unknown | authenticated | unauthenticated
      job_provider.dart
      wallet_provider.dart
    splash/
      wasl_app_splash_screen.dart   # Animated splash with logo image
    screens/
      auth/      login, otp, password, permissions, user_type, welcome
      client/    client_home, post_job, driver_offers, job_tracking, job_complete ...
      driver/    driver_home, driver_registration, job_detail, wallet, topup
      shared/    notifications, settings, support
      splash/    splash_screen.dart (thin wrapper around WaslAppSplashScreen)
    widgets/
      common/    wasl_button, wasl_toast, wasl_shake_widget, wasl_shimmer ...
```

## Auth flow
1. Splash → checks `AuthStatus`
2. If authenticated → clientHome or driverHome
3. If not → onboarding → login
4. Login accepts phone (OTP) or email (password) or Google
5. New user → userTypeSelect → permissions → welcome
6. Driver → driverRegistration (5 steps) → driverHome

**Critical**: GoRouter has NO `refreshListenable`. Removed intentionally — it caused a race condition where `notifyListeners()` from auth state changes interfered with manual `context.go()` calls after sign-in.

## User roles
- `client` — posts jobs, sees map, tracks driver
- `driver` — bids on jobs, has wallet, needs approval (`isApproved: false` until admin reviews)

## Firestore collections
- `users` — UserModel (id, name, phone, email, type, city, photoUrl, createdAt)
- `drivers` — DriverModel (id, name, phone, truckType, truckPhotoUrl, pricePerKm, city, walletBalance, cinNumber, isApproved, ...)
- `jobs` — JobModel (status: open/matched/inProgress/completed/cancelled)
- `offers` — OfferModel (jobId, driverId, price, status: pending/accepted/rejected)
- `transactions` — commission and topup records
- `topups` — manual topup requests (pending/confirmed by admin)

## Maps
- **Mobile**: Google Maps (`google_maps_flutter`) — works fine, has API key
- **Web**: Real interactive map via `flutter_map` (CartoDB dark tiles, OSM attribution) — free, no billing, no API key
- `kIsWeb` branch in both:
  - `client_home_screen.dart` — `_WebMap` (home tab map), uses `MapController`
  - `job_tracking_screen.dart` — `_LiveDriverMap` (`_LiveDriverMapState`), uses `fm.MapController` (flutter_map aliased as `fm` since `Marker`/etc. collide with `google_maps_flutter`)
- Live driver tracking already real-time via Firestore `drivers/{id}.location` (`GeoPoint`) stream from `AuthProvider._startLocationStream` — `_LiveDriverMap` only renders when `job.status == inProgress` and `matchedDriverId != null`

## Address autocomplete (post job screen)
- Uses **OpenStreetMap Nominatim** — free, no API key, no billing
- `lib/data/services/geocoding_service.dart` — `GeocodingService.searchMorocco(query)`
- Morocco-only results (`countrycodes=ma`), Arabic+French (`accept-language: ar,fr`)
- 600ms debounce, 8s timeout, max 5 results
- Shows inline dropdown in `_LocationField` in `post_job_screen.dart`

## Assets
```
assets/images/waslapp_logoo.png   # Transparent PNG logo (used on splash + login)
assets/images/waslapp_logo.jpeg   # Original logo with background (keep as backup)
assets/animations/                # Lottie files — success.json may be missing (crash risk)
assets/icons/
assets/fonts/
```

## Known issues / tech debt
- `app_strings.dart` — class S still has French strings
- `validators.dart` — error messages in French
- `main.dart` — title 'NaqlApp', French timeago locale
- `app_constants.dart` — `truckTypes` values are French ('Petit camion' etc.)
- `assets/animations/success.json` — missing, will crash if Lottie tries to load it
- New user profile creation gap: after Google sign-in → userTypeSelect, no Firestore user doc is created until driver registration or some explicit save
- Phone OTP: Morocco SMS needs to be enabled in Firebase Console → Authentication → Sign-in method
- Firebase phone auth rate-limits devices quickly during testing — add test phone numbers in Firebase Console to bypass
- Settings → "اللغة" opens a language picker bottom sheet (`_showLanguageSheet` in `settings_screen.dart`) — only Arabic is active; French/English show a "قريباً" badge and toast (no real localization wired up yet)
- **iOS Firebase not configured**: `firebase_options.dart` `ios` block is a placeholder (`appId: ...ios:000000000000000000000000`), no `GoogleService-Info.plist` in `ios/Runner/`, no Google Sign-In URL scheme in `Info.plist`. Needs `flutterfire configure` (or manual Firebase Console iOS app registration for bundle ID `com.naql.naqlApp`) before iOS builds can use Firebase.

## Firebase project
- Project ID: `naql-bc9e3`
- Auth methods: Phone, Email/Password, Google
- Storage rules: need to allow driver doc uploads
- Admin WhatsApp: `app_constants.dart` → `adminWhatsApp` (set real number before launch)
- Android: `com.google.gms.google-services` Gradle plugin is applied (`android/settings.gradle.kts` + `android/app/build.gradle.kts`) — required for `google-services.json` to be processed (Google Sign-In etc.). Was missing before, now fixed.

## Commission model
- `commissionRate: 0.12` (12%)
- Driver needs min wallet balance of 50 MAD (`minWalletBalance`)
- Wallet topped up manually, confirmed by admin in Firestore
