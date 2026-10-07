# PetBridge — Lost & Found Pet Reporting App

## Tech Stack
- **Frontend:** Flutter
- **Backend:** Firebase (Firestore, Authentication)
- **Image Hosting:** Cloudinary (unsigned upload preset) — used instead of Firebase Storage, which requires upgrading to the Blaze billing plan
- **Maps/Location:** Google Maps Flutter Plugin

## Setup Instructions
1. Clone the repo: `git clone https://github.com/Keshaini/petbridge_app.git`
2. Run `flutter pub get`
3. Firebase config files (`lib/firebase_options.dart`, `android/app/google-services.json`, `firebase.json`)
4. Run: `flutter run`
5. Select your target device/browser when prompted (Chrome recommended for quick testing)

## Firebase Project
All team members share the same Firebase project (**PetBridge**, project ID: `petbridge-3acc9`). Firestore is currently in test mode. No individual Firebase Console access is required to run or build the app — the shared config files handle the connection.

## Cloudinary Setup
Image uploads use Cloudinary's unsigned upload preset (`petbridge_unsigned`) configured in `lib/services/cloudinary_service.dart`. No additional setup needed to run the app — the Cloud Name is already set in the service file.

## Build APK
flutter build apk --release

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Team & Workload

| Member | Screens | Status |
|---|---|---|
| Binthuran | Splash, Onboarding, Login, Sign Up, Forgot Password, OTP, Home/Map |
| Keshaini | Create Report, Duplicate Warning Modal, Report Detail, Edit Report, Delete Confirmation |
| Ashfaq | My Reports, Search/Filter, Notifications, Empty State |
| Safa | Shelter Dashboard, Report Detail (Shelter), Settings, Profile, Edit Profile, Chat |

## Shared Components
Reusable widgets and constants are in `lib/widgets/` and `lib/constants/` — use `AppColors`, `AppTextStyles`, `PrimaryButton`, `AppTextField`, and `StatusPill` to keep visual consistency across screens rather than redefining styles.

## Folder Structure
lib/
├── constants/ # Colors, text styles, strings
├── models/ # ReportModel, UserModel, MessageModel
├── services/ # firestore_service.dart, cloudinary_service.dart
├── widgets/ # Shared reusable UI components
├── screens/
│ ├── auth/ # Binthuran
│ ├── reporting/ # Keshaini
│ ├── myreports/ # Ashfaq
│ └── shelter/ # Safa
└── navigation/ # app_router.dart