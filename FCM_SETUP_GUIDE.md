# FCM Setup and Testing Guide

## Overview
This guide explains how to set up and test Firebase Cloud Messaging (FCM) notifications in the Aadhaar Locator app.

## What's Been Implemented

### 1. FCM Service (`lib/features/notifications/services/fcm_service.dart`)
- **Automatic FCM token generation** when the app starts
- **Token storage** in Firestore (both in user document and separate collection)
- **Token refresh handling** when Firebase refreshes the token
- **Permission management** for notifications
- **Background message handling**

### 2. Push Notification Service (`lib/features/notifications/services/push_notification_service.dart`)
- **Location share notifications** to specific users
- **Bulk notifications** to multiple users
- **Emergency notifications** to all users
- **Topic-based notifications**

### 3. Enhanced Authentication Integration
- **FCM token generation** automatically during login
- **Token cleanup** during logout
- **Token updates** when user profile is loaded

### 4. Development Helper Service (`lib/core/services/development_helper_service.dart`)
- **Comprehensive testing** of Firebase services
- **FCM functionality testing**
- **Test user creation** for development
- **Debug information** collection

### 5. Debug Screen (`lib/features/debug/presentation/debug_screen.dart`)
- **Interactive testing interface**
- **Real-time test results**
- **FCM token verification**
- **Test user management**

## How FCM Works Now

### 1. App Startup
```dart
// In main.dart
await FCMService.initialize();
```
- Requests notification permissions
- Generates FCM token
- Sets up message handlers

### 2. User Login
```dart
// In auth_providers.dart
await FCMService.updateTokenForUser(user.uid);
```
- Generates new FCM token
- Saves token to Firestore
- Updates user profile

### 3. Token Storage
The FCM token is stored in two places:
- **User document**: `users/{uid}/fcmToken`
- **FCM collection**: `fcmTokens/{uid}` (for easier querying)

### 4. Message Handling
- **Foreground messages**: Show local notifications
- **Background messages**: Handled by Firebase
- **Notification taps**: Navigate to appropriate screens

## Testing FCM Functionality

### Method 1: Use the Debug Screen
1. Navigate to the debug screen in your app
2. Click "Run All Tests" to check everything
3. Click "Test FCM Only" to test just FCM
4. Click "Create Test User" to create a test account

### Method 2: Check Console Logs
Look for these log messages:
```
🔔 FCM: Initializing FCM service...
✅ FCM: Service initialized successfully
🔔 FCM: Got token: [token]...
💾 FCM: Saving token to Firestore for user: [uid]
✅ FCM: Token saved to Firestore successfully
```

### Method 3: Verify in Firestore
Check these collections:
- `users/{uid}/fcmToken` - Should contain the FCM token
- `fcmTokens/{uid}` - Should contain token metadata

## Common Issues and Solutions

### Issue 1: "FCM token not available"
**Symptoms**: No FCM token generated, notifications not working
**Solutions**:
1. Check Firebase configuration in `firebase_options.dart`
2. Verify Google Play Services are up to date
3. Check notification permissions in device settings
4. Run the debug tests to identify the issue

### Issue 2: "Token saved to Firestore successfully" but notifications still not working
**Symptoms**: Token is saved but no notifications received
**Solutions**:
1. Verify the token is valid by testing with Firebase Console
2. Check if the app is in background/foreground
3. Verify notification permissions are granted
4. Test with a simple notification first

### Issue 3: Login failing with "invalid-credential"
**Symptoms**: Can't log in, FCM token not generated
**Solutions**:
1. Use the debug screen to create a test user
2. Check Firebase Auth configuration
3. Verify the user exists in Firebase Console
4. Check network connectivity

## Testing Notifications

### 1. Test Local Notifications
```dart
await NotificationService.showNotification(
  title: 'Test',
  body: 'This is a test notification',
);
```

### 2. Test FCM Notifications
Use the debug screen or test with Firebase Console:
1. Go to Firebase Console > Cloud Messaging
2. Send a test message to your FCM token
3. Check if the notification appears

### 3. Test Location Share Notifications
```dart
await PushNotificationService.sendLocationShareNotification(
  recipientUid: 'user_uid',
  senderName: 'Test User',
  latitude: 12.9716,
  longitude: 77.5946,
);
```

## Debug Commands

### Run Comprehensive Tests
```dart
final results = await DevelopmentHelperService.runComprehensiveTests();
```

### Test FCM Only
```dart
final results = await FCMTestService.runAllTests();
```

### Create Test User
```dart
final result = await DevelopmentHelperService.createTestUser(
  email: 'test@example.com',
  password: 'testpass123',
);
```

### Check Firebase Status
```dart
final status = await DevelopmentHelperService.checkFirebaseAuthStatus();
```

## Next Steps

### 1. Test the Current Implementation
- Run the debug tests
- Verify FCM token generation
- Test local notifications
- Test FCM notifications

### 2. Set Up Cloud Functions (Optional)
For production push notifications, you'll need Cloud Functions:
- `sendLocationShareNotification`
- `sendNotificationToMultipleUsers`
- `sendEmergencyNotification`

### 3. Customize Notification Handling
- Modify notification appearance
- Add custom actions
- Handle different notification types
- Implement notification routing

## Troubleshooting Checklist

- [ ] Firebase project configured correctly
- [ ] `google-services.json` added to Android
- [ ] `GoogleService-Info.plist` added to iOS
- [ ] Notification permissions granted
- [ ] FCM token generated successfully
- [ ] Token saved to Firestore
- [ ] App can receive notifications
- [ ] Background notifications working
- [ ] Notification taps handled correctly

## Support

If you encounter issues:
1. Check the console logs for error messages
2. Run the debug tests to identify problems
3. Verify Firebase configuration
4. Check device notification settings
5. Test on different devices/emulators

