# Green Rewards App

A Flutter application for managing trash rewards and user engagement.

## Firebase Configuration

### Password Reset Setup

If you encounter reCAPTCHA errors during password reset, follow these steps:

1. **Go to Firebase Console** → Authentication → Settings → Advanced
2. **Enable reCAPTCHA Enterprise** for your project
3. **Add your app's SHA-1 fingerprint** to the Android configuration
4. **Configure reCAPTCHA** in the Firebase Console

### Getting SHA-1 Fingerprint

Run this command to get your app's SHA-1 fingerprint:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Alternative Solution

If reCAPTCHA issues persist, the app includes a retry mechanism that will attempt the password reset up to 3 times with exponential backoff.

## Features

- User authentication with email/password
- Password reset functionality
- Real-time points tracking
- Transaction management
- Forum and community features
- Rewards system
- Leaderboards
- Modern UI with animations

## Dependencies

- Flutter SDK
- Firebase Core
- Firebase Auth
- Cloud Firestore
- Google Sign-In
- Facebook Auth
- Apple Sign-In

## Getting Started

1. Clone the repository
2. Run `flutter pub get`
3. Configure Firebase project
4. Run the app with `flutter run`
