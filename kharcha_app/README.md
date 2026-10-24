# Kharcha app (Flutter)

Riverpod 3 + go_router + Dio + Firebase Auth. Clean architecture per feature: `data/` (Dio, JSON), `domain/` (entities, use cases, repository interfaces), `presentation/` (pages, providers).
This folder holds `lib/`, `test/`, `pubspec.yaml`, `firebase.json`: copy them into your Flutter project (the one that has `android/`, `ios/`, `web/`). `lib/firebase_options.dart` is yours and was not touched.

## Run
```bash
flutter pub get
flutter run                                   # DEMO_DATA=true by default: sample data, no backend needed (sign-in still uses Firebase)
# against the real backend (Android emulator reaches your PC at 10.0.2.2):
flutter run --dart-define=DEMO_DATA=false --dart-define=API_BASE_URL=http://10.0.2.2:4000
# backend in AUTH_MODE=dev (no Firebase Admin): send a dev token instead of the Firebase one
flutter run --dart-define=DEMO_DATA=false --dart-define=DEV_AUTH_TOKEN=dev:demo
flutter test
flutter analyze
```
Native setup the scanner needs (not in `lib/`): **Android** `<uses-permission android:name="android.permission.CAMERA"/>` and `minSdkVersion 24`; **iOS** `NSCameraUsageDescription` in `Info.plist`.

## Features
`auth` login, sign up, reset password · 
`receipts` list, detail, review/edit, photo viewer, offline upload queue ·
`scanner` camera + edge detection + crop (OpenCV, phones only) · 
`dashboard` month summary, calendar, category breakdown ·
`budgets` per-category limits with 80% / 100% states · 
`insights` plain-language findings · 
`alerts` server notifications (bell on Home) ·
`profile` onboarding and settings.

## How it talks to the backend
- Paths: `lib/core/network/api_endpoints.dart`; contract: `../backend/docs/api-contract.md`.
- The screens use eight short category names (Dining, Health, Bills ...). The backend's defaults are named differently
  (Food & Dining, Healthcare, Utilities ...). `lib/core/network/category_names.dart` translates at the network edge only.
- Budgets are keyed by category id on the server; `category_directory.dart` looks the id up from the category name.
- Every datasource has a demo twin in `lib/core/demo/`; `Env.useDemoData` picks one.
