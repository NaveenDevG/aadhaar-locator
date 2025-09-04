# Aadhaar Locator

A Flutter application for secure location sharing with Aadhaar authentication, Firebase integration, and FCM notifications.

## Features

- 🔐 **Aadhaar Authentication**: Secure user registration and login with Aadhaar verification
- 📍 **Location Sharing**: Share and view locations on interactive maps
- 🔔 **Push Notifications**: Real-time notifications using Firebase Cloud Messaging
- ☁️ **Cloud Storage**: User data stored securely in Firebase Firestore
- 📱 **Cross-Platform**: Works on Android, iOS, and Web

## Prerequisites

- Flutter SDK (3.9.0 or higher)
- Dart SDK (3.9.0 or higher)
- Android Studio / Xcode (for mobile development)
- Firebase project with the following services enabled:
  - Authentication
  - Firestore Database
  - Cloud Messaging
  - Cloud Functions (optional)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd aadhaar_locator
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Enable the following services:
   - Authentication (Email/Password)
   - Firestore Database
   - Cloud Messaging

#### Android Configuration
1. Add your Android app in Firebase Console
2. Download `google-services.json` and place it in `android/app/`
3. Update the package name in `android/app/build.gradle.kts` if needed

#### iOS Configuration
1. Add your iOS app in Firebase Console
2. Download `GoogleService-Info.plist` and place it in `ios/Runner/`
3. Update the bundle ID in `ios/Runner/Info.plist` if needed

#### Web Configuration
1. Add your web app in Firebase Console
2. Update the Firebase config in `web/firebase-config.js` with your actual values

### 4. Update Configuration Files

Replace the placeholder values in the following files with your actual Firebase project values:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `web/firebase-config.js`

**Important**: The current configuration files contain placeholder values and will not work. You must replace them with your actual Firebase project configuration.

### 5. Run the Application

```bash
# For Android
flutter run -d android

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome
```

## Project Structure

```
lib/
├── core/                    # Core utilities and configurations
│   ├── errors/             # Error handling
│   ├── routing/            # App routing
│   ├── theme/              # App theming
│   ├── utils/              # Utility functions
│   └── widgets/            # Common widgets
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   │   ├── data/          # Data layer
│   │   ├── presentation/  # UI layer
│   │   ├── providers/     # State management
│   │   └── services/      # Business logic
│   ├── dashboard/         # Dashboard screen
│   ├── maps/              # Map functionality
│   ├── notifications/     # Push notifications
│   └── splash/            # Splash screen
└── main.dart              # App entry point
```

## Key Components

### Authentication
- **User Registration**: Collects Aadhaar information for verification
- **User Login**: Secure email/password authentication
- **Profile Management**: Stores user data in Firestore

### Location Services
- **Google Maps Integration**: Interactive map display
- **Location Sharing**: Share current location with other users
- **Real-time Updates**: Live location tracking

### Notifications
- **FCM Integration**: Firebase Cloud Messaging for push notifications
- **Local Notifications**: In-app notification display
- **Background Handling**: Notification processing when app is closed

## Security Features

- Aadhaar number validation
- Secure password requirements
- Firebase Security Rules for data access
- Encrypted data transmission

## Dependencies

- **State Management**: `flutter_riverpod`
- **Firebase**: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`
- **Maps**: `google_maps_flutter`
- **Location**: `geolocator`
- **Notifications**: `flutter_local_notifications`
- **UI**: `lottie`, `cupertino_icons`

## Troubleshooting

### Common Issues

1. **Firebase Initialization Error**
   - Ensure all configuration files are properly placed
   - Verify Firebase project settings
   - Check internet connectivity

2. **Build Errors**
   - Run `flutter clean` and `flutter pub get`
   - Verify all dependencies are compatible
   - Check platform-specific configurations

3. **Authentication Issues**
   - Verify Firebase Authentication is enabled
   - Check email/password sign-in method is active
   - Ensure proper error handling in UI

### Getting Help

- Check Flutter documentation: [flutter.dev](https://flutter.dev)
- Firebase documentation: [firebase.google.com](https://firebase.google.com)
- Create an issue in the project repository

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This application is for educational and demonstration purposes. Ensure compliance with local laws and regulations regarding Aadhaar data handling and privacy protection.
