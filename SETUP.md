# Setup Guide for IIT Delhi OAE Flutter App

## 🚀 Quick Start

This guide will help you set up the IIT Delhi OAE Flutter application for development.

## 📋 Prerequisites

### Required Software
- **Flutter SDK** (^3.8.1) - [Download here](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (included with Flutter)
- **Git** - [Download here](https://git-scm.com/)
- **IDE**: Android Studio, VS Code, or IntelliJ IDEA

### For Mobile Development
- **Android**: Android Studio with Android SDK
- **iOS**: Xcode (macOS only)
- **macOS**: Xcode Command Line Tools

## 🔧 Installation Steps

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd flutter_app
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `iitd-oae-app` (or your preferred name)
4. Enable Google Analytics (optional)
5. Click "Create project"

#### Step 2: Enable Firebase Services
In your Firebase project, enable these services:
- **Authentication** → Email/Password
- **Firestore Database** → Start in test mode
- **Storage** → Start in test mode
- **Cloud Messaging** → Enable

#### Step 3: Add Apps to Firebase Project

##### Android App
1. In Firebase Console, click "Add app" → Android
2. Android package name: `com.iitd.oae`
3. App nickname: `IITD OAE Android`
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`

##### iOS App
1. In Firebase Console, click "Add app" → iOS
2. iOS bundle ID: `com.iitd.oae`
3. App nickname: `IITD OAE iOS`
4. Download `GoogleService-Info.plist`
5. Place it in `ios/Runner/GoogleService-Info.plist`

##### macOS App
1. In Firebase Console, click "Add app" → iOS
2. iOS bundle ID: `com.iitd.oae`
3. App nickname: `IITD OAE macOS`
4. Download `GoogleService-Info.plist`
5. Place it in `macos/Runner/GoogleService-Info.plist`

#### Step 4: Configure Firebase Options

1. **Replace placeholders in `lib/firebase_options.dart`**:
   ```dart
   // Get these values from Firebase Console → Project Settings → General
   static const FirebaseOptions web = FirebaseOptions(
     apiKey: 'YOUR_ACTUAL_WEB_API_KEY',
     appId: 'YOUR_ACTUAL_WEB_APP_ID',
     messagingSenderId: 'YOUR_ACTUAL_SENDER_ID',
     projectId: 'YOUR_ACTUAL_PROJECT_ID',
     authDomain: 'YOUR_ACTUAL_PROJECT_ID.firebaseapp.com',
     storageBucket: 'YOUR_ACTUAL_PROJECT_ID.firebasestorage.app',
     measurementId: 'YOUR_ACTUAL_MEASUREMENT_ID',
   );
   ```

2. **Update `firebase.json`**:
   ```json
   {
     "projectId": "YOUR_ACTUAL_PROJECT_ID",
     "appId": "YOUR_ACTUAL_APP_ID"
   }
   ```

### 4. Configure Firestore Rules

Update `firestore.rules` with your security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow admins to read all data
    match /{document=**} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### 5. Configure Storage Rules

Update `storage.rules`:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 🏃‍♂️ Running the Application

### Development Mode

```bash
# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d chrome    # Web
flutter run -d android   # Android
flutter run -d ios       # iOS
flutter run -d macos     # macOS
```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Firebase Configuration Errors
```
Error: No Firebase App '[DEFAULT]' has been created
```
**Solution**: Ensure `google-services.json` and `GoogleService-Info.plist` are in correct locations.

#### 2. Permission Denied Errors
```
Error: Permission denied (publickey)
```
**Solution**: Check your SSH keys or use HTTPS for Git operations.

#### 3. Flutter Version Issues
```
Error: Flutter version mismatch
```
**Solution**: Run `flutter doctor` and update Flutter if needed.

#### 4. iOS Build Issues
```
Error: No provisioning profile found
```
**Solution**: Configure iOS signing in Xcode.

### Debug Commands

```bash
# Check Flutter installation
flutter doctor

# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check for issues
flutter analyze
flutter test
```

## 📱 Platform-Specific Setup

### Android Setup

1. **Enable Developer Options** on your Android device
2. **Enable USB Debugging**
3. **Install Android Studio** and Android SDK
4. **Create Android Virtual Device** (AVD) for testing

### iOS Setup (macOS only)

1. **Install Xcode** from App Store
2. **Install Xcode Command Line Tools**:
   ```bash
   xcode-select --install
   ```
3. **Open iOS Simulator**:
   ```bash
   open -a Simulator
   ```

### Web Setup

1. **Enable Web Support**:
   ```bash
   flutter config --enable-web
   ```
2. **Run on Chrome**:
   ```bash
   flutter run -d chrome
   ```

## 🔐 Security Checklist

Before committing code:

- [ ] No API keys in code
- [ ] No sensitive data in logs
- [ ] Firebase rules configured
- [ ] Authentication working
- [ ] Input validation implemented
- [ ] Error handling in place

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

## 🤝 Getting Help

If you encounter issues:

1. Check the [troubleshooting section](#troubleshooting)
2. Search existing [GitHub issues](https://github.com/your-repo/issues)
3. Create a new issue with detailed information
4. Contact the development team

---

**Note**: This setup guide assumes you have basic knowledge of Flutter and Firebase. For beginners, we recommend completing the [Flutter Getting Started](https://flutter.dev/docs/get-started) tutorial first. 