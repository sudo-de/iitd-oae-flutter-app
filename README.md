# IIT Delhi OAE Flutter App

A comprehensive Flutter application for the Office of Accessible Education (OAE) at IIT Delhi, providing transportation services and academic management features for students with disabilities.

## 🚀 Features

- **Student Dashboard**: Book rides, view class schedules, submit complaints
- **Driver Dashboard**: Accept rides, view earnings, manage ride history
- **Admin Panel**: User management, complaint handling, analytics
- **Real-time Notifications**: Push notifications for ride updates
- **Firebase Integration**: Authentication, Firestore database, Cloud Storage
- **Cross-platform**: Android, iOS

## 📱 Screenshots

Check out the `screenshots/` directory for app previews.
| Login Screen | Admin Panel | Student Dashboard | Student ID Profile | Book Ride | Class Schedule | Driver Dashboard |
|--------------|-------------|-------------------|--------------------|-----------|----------------|------------------|
| ![Login Screen](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.55.58.png) | ![Admin Panel](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.55.30.png) | ![Student Dashboard](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.52.07.png) | ![Student ID Profile](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.53.02.png) | ![Book Ride](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.53.10.png) | ![Class Schedule](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.53.56.png) | ![Driver Dashboard](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.54.34.png) |

| My complaint | Complaints | User Management | Ride History | Earnings | Menu list | Analytics |  
|--------------|------------|-----------------|--------------|----------|-----------|-----------|
| ![My complaint](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.54.11.png) | ![Complaints](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.54.06.png) | ![User Management](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.55.37.png) | ![Ride History](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.54.48.png) | ![Earnings](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.54.55.png) | ![Notifications](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.52.54.png) | ![Analytics](screenshots/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-07-17%20at%2003.55.43.png) |


## 🔧 Setup Instructions

### Prerequisites

- Flutter SDK (^3.8.1)
- Dart SDK
- Firebase project
- Android Studio / Xcode (for mobile development)

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd flutter_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

**⚠️ IMPORTANT: You need to configure Firebase before running the app**

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Enable Authentication, Firestore, Storage, and Cloud Messaging

#### Step 2: Configure Firebase Options
1. Replace placeholder values in `lib/firebase_options.dart`:
   ```dart
   // Replace these with your actual Firebase configuration
   apiKey: 'YOUR_API_KEY',
   appId: 'YOUR_APP_ID',
   messagingSenderId: 'YOUR_SENDER_ID',
   projectId: 'YOUR_PROJECT_ID',
   ```

2. Update `firebase.json` with your project details:
   ```json
   {
     "projectId": "YOUR_PROJECT_ID",
     "appId": "YOUR_APP_ID"
   }
   ```

#### Step 3: Download Configuration Files
1. **Android**: Download `google-services.json` from Firebase Console
   - Place it in `android/app/google-services.json`
   
2. **iOS**: Download `GoogleService-Info.plist` from Firebase Console
   - Place it in `ios/Runner/GoogleService-Info.plist`
   
3. **macOS**: Download `GoogleService-Info.plist` from Firebase Console
   - Place it in `macos/Runner/GoogleService-Info.plist`

#### Step 4: Configure Firestore Rules
Update `firestore.rules` and `storage.rules` according to your security requirements.

### 4. Run the Application

```bash
# For development
flutter run

# For specific platform
flutter run -d chrome  # Web
flutter run -d android # Android
flutter run -d ios     # iOS
```

## 🔒 Security Notes

### Files Excluded from Git
The following sensitive files are automatically excluded via `.gitignore`:
- `android/app/google-services.json` for Android
- `ios/Runner/GoogleService-Info.plist` for iOS
- `macos/Runner/GoogleService-Info.plist` for macOS
- `.firebaserc` (Firebase project configuration)
- `.env` files (environment variables)
- API keys and certificates

### Environment Variables
For additional security, consider using environment variables for sensitive data:
```bash
# Create .env file (not tracked by git)
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
```

## 📁 Project Structure

```
lib/
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Business logic
├── utils/           # Utilities
└── widgets/         # Reusable widgets
```

## 🛠️ Development

### Code Style
This project follows Flutter's official style guide. Run:
```bash
flutter analyze
dart format .
```

### Testing
```bash
flutter test
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

For support and questions, please contact the development team or create an issue in the repository.

---

**Note**: This is a public repository. Never commit sensitive information like API keys, passwords, or personal data. Always use environment variables or secure configuration files for sensitive data.
