# Cloud Functions Setup Guide

## Overview
This guide explains how to set up Firebase Cloud Functions to enable push notifications in the Aadhaar Locator app.

## Why Cloud Functions Are Needed

The app currently shows **local notifications** instead of **push notifications** to other users because:

1. **Local notifications** only appear on the device that triggers them (the sender's device)
2. **Push notifications** require a server-side component to send messages to other users' devices
3. **Cloud Functions** provide this server-side capability using Firebase's infrastructure

## Current Issue

When you share your location, you see a confirmation notification because it's a **local notification** on your device. Other users don't receive notifications because the app is not actually sending **push notifications** to their devices.

## Solution: Set Up Cloud Functions

### Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase

```bash
firebase login
```

### Step 3: Initialize Cloud Functions

In your project root directory:

```bash
firebase init functions
```

When prompted:
- Select your Firebase project
- Choose JavaScript (or TypeScript if you prefer)
- Install dependencies? Yes

### Step 4: Deploy Cloud Functions

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Step 5: Verify Deployment

Check the Firebase Console:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to Functions section
4. You should see the deployed functions:
   - `sendLocationShareNotification`
   - `sendNotificationToMultipleUsers`
   - `sendEmergencyNotification`
   - `sendTestNotification`

## Testing the Setup

### Method 1: Use the Debug Screen
1. Open your app
2. Go to the debug screen
3. Click "Test FCM Only"
4. Check if push notifications work

### Method 2: Test Location Sharing
1. Have two users logged in on different devices
2. Share location from one device
3. The other device should receive a push notification

### Method 3: Check Console Logs
Look for these messages:
```
✅ Push: Location share notification sent via Cloud Function
```

Instead of:
```
⚠️ Push: Cloud Function failed, trying fallback method
```

## Troubleshooting

### Issue 1: "Cloud Function not found"
**Solution**: Make sure you've deployed the functions:
```bash
firebase deploy --only functions
```

### Issue 2: "Permission denied"
**Solution**: Check Firebase project permissions and make sure you're logged in:
```bash
firebase login
firebase use <your-project-id>
```

### Issue 3: Functions deployed but notifications still not working
**Solutions**:
1. Check if FCM tokens are being generated and saved
2. Verify notification permissions are granted
3. Test with the debug screen
4. Check Firebase Console for function logs

### Issue 4: "Invalid FCM token"
**Solutions**:
1. Make sure users are logged in
2. Check if FCM tokens are being saved to Firestore
3. Verify the token format in Firebase Console

## Alternative: Local Development

For local development, you can run Cloud Functions locally:

```bash
cd functions
npm run serve
```

Then update your app to use the local emulator (add this to your Firebase initialization):

```dart
FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
```

## What Happens After Setup

Once Cloud Functions are deployed:

1. **Location sharing** will send actual push notifications to other users
2. **Other users** will receive notifications on their devices (not just the sender)
3. **Notifications** will work even when the app is in the background
4. **Emergency notifications** will be sent to all users

## Security Notes

- Cloud Functions run with admin privileges
- They have access to your entire Firebase project
- Make sure to implement proper authentication checks
- Consider rate limiting for production use

## Cost Considerations

- Cloud Functions have a free tier
- Each function invocation counts toward your quota
- Check Firebase pricing for your usage patterns

## Next Steps

1. Deploy the Cloud Functions
2. Test with multiple devices
3. Verify push notifications are working
4. Consider implementing additional features like:
   - Notification history
   - User preferences
   - Advanced notification types

## Support

If you encounter issues:
1. Check the Firebase Console for function logs
2. Verify your Firebase project configuration
3. Test with the debug screen in the app
4. Check device notification settings


