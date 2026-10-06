# PetBridge — Lost & Found Pet Reporting App

## Tech Stack
Flutter, Firebase (Firestore, Auth, Storage), Google Maps Flutter Plugin

## Setup Instructions
1. Clone the repo: `git clone [repo-url]`
2. Run `flutter pub get`
3. Add your `firebase_options.dart` (see `.env.example` / ask team for Firebase config)
4. Run: `flutter run`

## Build APK
`flutter build apk --release`
Output: `build/app/outputs/flutter-apk/app-release.apk`

## Team & Workload
| Member | Screens |
|---|---|
| Binthuran | Splash, Onboarding, Login, Sign Up, Forgot Password, OTP, Home/Map |
| Keshaini | Create Report, Duplicate Warning Modal, Report Detail, Edit Report, Delete Confirmation |
| Ashfaq | My Reports, Search/Filter, Notifications, Empty State |
| Safa | Shelter Dashboard, Report Detail (Shelter), Settings, Profile, Edit Profile, Chat |