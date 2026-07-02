# SafeSip Firebase & Google Maps Setup

## Firebase (Firestore)

1. Create a project at [Firebase Console](https://console.firebase.google.com/).
2. Enable **Cloud Firestore** (Create database, start in test mode or use the rules in `firestore.rules`).
3. Run **FlutterFire CLI** to link the app and generate config:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This creates `lib/firebase_options.dart` and adds `google-services.json` (Android) / `GoogleService-Info.plist` (iOS).

4. Deploy Firestore rules (optional):
   ```bash
   firebase deploy --only firestore:rules
   ```
   (Copy `firestore.rules` into your Firebase project's `firestore.rules` or use the Firebase Console.)

5. **Seed demo pins**: In Firestore Console, add a few documents to the `readings` collection with fields: `lat`, `lng`, `contaminant`, `timestamp`. The app also shows built-in seed pins when Firebase is not configured.

## Google Maps API key

1. In [Google Cloud Console](https://console.cloud.google.com/), enable **Maps SDK for Android** and **Maps SDK for iOS** for your project.
2. Create an API key (Credentials).
3. **Android**: In `android/app/src/main/AndroidManifest.xml`, replace `YOUR_GOOGLE_MAPS_API_KEY` with your key.
4. **iOS**: In `ios/Runner/AppDelegate.swift`, replace `YOUR_GOOGLE_MAPS_API_KEY` with your key.

Without a key, the map may show a blank or error state on the device.
