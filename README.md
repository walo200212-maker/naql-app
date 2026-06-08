# NaqlApp (نقل)

A truck moving marketplace for Morocco — Casablanca & Rabat.

Clients post moving jobs, drivers bid with their price, the client picks the best offer.
The platform auto-deducts **12% commission** from the driver's pre-loaded wallet after each completed job.

---

## Architecture

| Layer | Details |
|---|---|
| **Framework** | Flutter (single codebase — iOS + Android) |
| **State management** | Provider (AuthProvider, JobProvider, WalletProvider) |
| **Backend** | Firebase Auth (Phone OTP) · Firestore · Storage · FCM |
| **Navigation** | go_router |
| **Maps** | google_maps_flutter · geolocator · geoflutterfire_plus |
| **UI** | Dark-first, orange accent #F97316, Cairo font |

---

## Project structure

```
lib/
  core/
    constants/   app_constants.dart  app_routes.dart
    theme/       app_colors.dart  app_text_styles.dart  app_theme.dart
    utils/       currency_formatter.dart  distance_calculator.dart  validators.dart
    localization/ app_strings.dart
  data/
    models/      user_model  driver_model  job_model  offer_model
                 transaction_model  topup_model
    services/    auth_service  firestore_service  storage_service  notification_service
  presentation/
    providers/   auth_provider  job_provider  wallet_provider
    screens/
      splash/ onboarding/ auth/
      client/  home · post_job · job_posted · driver_offers · job_tracking · job_complete
      driver/  registration · home · job_detail · wallet · topup
      shared/  support · settings
    widgets/common/  naql_button  status_badge  skeleton_loader
  app_router.dart
  main.dart
```

---

## Setup

### 1. Prerequisites

- Flutter SDK >= 3.11.0
- Dart SDK >= 3.11.0
- Firebase project with **Authentication (Phone)**, **Firestore**, **Storage**, **Cloud Messaging** enabled

### 2. Clone & install

```bash
git clone <your-repo>
cd naql_app
flutter pub get
```

### 3. Firebase configuration

**Option A — FlutterFire CLI (recommended)**

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart` and places `google-services.json` / `GoogleService-Info.plist` automatically.
Then update `main.dart`:

```dart
import 'firebase_options.dart';
// ...
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

**Option B — Manual**

- Android: download `google-services.json` → `android/app/google-services.json`
- iOS: download `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist`

`Firebase.initializeApp()` (no options) in `main.dart` will pick them up automatically.

### 4. Google Maps API key

1. Enable **Maps SDK for Android** and **Maps SDK for iOS** in Google Cloud Console.
2. Android — add your key to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_KEY_HERE"/>
```

3. iOS — add your key to `ios/Runner/AppDelegate.swift`:

```swift
GMSServices.provideAPIKey("YOUR_KEY_HERE")
```

4. Update `AppConstants.googleMapsApiKey` in `lib/core/constants/app_constants.dart`.

### 5. Cairo font (optional but recommended)

1. Download from https://fonts.google.com/specimen/Cairo
2. Place the `.ttf` files in `assets/fonts/`:
   - `Cairo-Regular.ttf`
   - `Cairo-Medium.ttf`
   - `Cairo-SemiBold.ttf`
   - `Cairo-Bold.ttf`
   - `Cairo-ExtraBold.ttf`
3. Uncomment the `fonts:` block in `pubspec.yaml`.

### 6. Tawk.to live chat

1. Create a Tawk.to account at https://www.tawk.to
2. Copy your **Property ID** and **Widget ID** from the widget embed code.
3. Set them in `lib/core/constants/app_constants.dart`:

```dart
static const String tawkPropertyId = 'YOUR_PROPERTY_ID';
static const String tawkWidgetId   = 'YOUR_WIDGET_ID';
```

### 7. Admin WhatsApp number

Update `adminWhatsApp` in `app_constants.dart` with the real number (international format, no spaces):

```dart
static const String adminWhatsApp = '+212600000000';
```

### 8. Firestore indexes

Firestore requires composite indexes for the queries used. Run the app once — Firestore will print links to the console to create the missing indexes automatically.

Required indexes:
- `jobs`: `(status, city, createdAt DESC)`
- `jobs`: `(clientId, createdAt DESC)`
- `offers`: `(jobId, status, totalPrice ASC)`
- `offers`: `(driverId, createdAt DESC)`
- `transactions`: `(driverId, createdAt DESC)`
- `topups`: `(driverId, createdAt DESC)`

### 9. Firestore security rules (starter)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    match /drivers/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
    }
    match /jobs/{jobId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    match /offers/{offerId} {
      allow read, write: if request.auth != null;
    }
    match /transactions/{txId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    match /topups/{topupId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if false;
    }
  }
}
```

### 10. Run

```bash
flutter run
```

---

## Business rules

| Rule | Value |
|---|---|
| Commission rate | 12% of agreed price |
| Minimum wallet to accept jobs | 50 MAD |
| Low balance warning threshold | 100 MAD |
| Wallet top-up method | CashPlus / Wafacash (manual reference, confirmed by admin) |
| Payment client to driver | Cash in person |
| Supported cities | Casablanca, Rabat, Casablanca-Rabat intercity |

---

## Key flows

```
CLIENT
  Register (phone OTP) → Post job (pickup/dropoff/photos) → Receive driver bids
  → Pick best driver → Confirm start → Pay cash → Rate driver

DRIVER
  Register (truck type/city/price per km/photo) → Top up wallet → Browse open jobs
  → Submit bid with price → Wait for client selection → Complete job
  → 12% auto-deducted from wallet
```

---

## Environment checklist

- [ ] `google-services.json` placed in `android/app/`
- [ ] `GoogleService-Info.plist` placed in `ios/Runner/`
- [ ] Google Maps API key set in `AndroidManifest.xml` and `AppDelegate.swift`
- [ ] `AppConstants.adminWhatsApp` set to real number
- [ ] `AppConstants.tawkPropertyId` and `tawkWidgetId` set
- [ ] Cairo fonts added to `assets/fonts/` and uncommented in `pubspec.yaml`
- [ ] Firestore indexes created
- [ ] Firestore security rules published
