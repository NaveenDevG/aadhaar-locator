# Notification Troubleshooting Guide

## Problem: Test Notifications Not Working

You're experiencing issues where:
- Test notifications are not working
- Notifications are only sent to 0 users even though 3 are online
- Push notifications are not reaching other users

## Quick Fix Steps 🚀

### Step 1: Check Notification Status
1. Open the app
2. Go to Location Sharing screen
3. Click the **ℹ️ Check Status** button
4. Review the status dialog for any issues

### Step 2: Refresh FCM Token
1. Click the **🔄 Refresh FCM Token** button
2. Check console logs for success/error messages
3. This will regenerate and save your FCM token

### Step 3: Debug Current State
1. Click the **🔍 Debug State** button
2. Check console logs for detailed information about:
   - Logged-in users
   - FCM tokens
   - User documents

### Step 4: Test Notifications
1. Click the **🧪 Test Notification** button
2. Check console logs for detailed test results
3. This will test both local and push notifications

## Common Issues and Solutions 🔧

### Issue 1: FCM Token Not Generated
**Symptoms**: 
- "FCM Token: Missing" in status
- "FCM Service available: false"

**Solutions**:
1. Click **🔄 Refresh FCM Token** button
2. Check device notification permissions
3. Restart the app
4. Check Firebase configuration

### Issue 2: User Not Marked as Logged In
**Symptoms**:
- "User Is Logged In: false"
- Other users don't see you online

**Solutions**:
1. Log out and log back in
2. Check if `completeFirstLogin()` was called
3. Verify Firestore rules allow user updates

### Issue 3: Cloud Functions Not Deployed
**Symptoms**:
- "Cloud Function not deployed" in console
- Push notifications fail with function errors

**Solutions**:
1. Deploy Cloud Functions:
   ```bash
   firebase deploy --only functions
   ```
2. Check Firebase Console > Functions section
3. Verify function names match exactly

### Issue 4: FCM Tokens Not Saved to Firestore
**Symptoms**:
- "User Has FCM Token: false"
- "FCM Token Document Exists: false"

**Solutions**:
1. Click **🔄 Refresh FCM Token** button
2. Check Firestore rules allow FCM token updates
3. Verify user authentication is working

## Detailed Debugging Steps 🔍

### 1. Check Console Logs
Look for these key messages:
```
🔍 LocationSharingService: === DEBUGGING CURRENT STATE ===
🔍 LocationSharingService: Logged-in users count: [number]
🔍 LocationSharingService: FCM tokens collection count: [number]
🔍 LocationSharingService: User [uid]: isLoggedIn=[true/false], hasFcmToken=[true/false]
```

### 2. Check FCM Service Status
Look for:
```
🔍 LocationSharingService: FCM Service available: [true/false]
🔍 LocationSharingService: FCM Current token: [Present/Missing]
```

### 3. Check User Documents
Look for:
```
🔍 LocationSharingService: User [uid]: isLoggedIn=[true/false], hasFcmToken=[true/false]
```

### 4. Check Push Notification Attempts
Look for:
```
📤 LocationSharingService: Attempting to send notification to [name] ([uid])
🔍 Push: Recipient [uid] - FCM Token: [Present/Missing]
```

## Expected Console Output ✅

### Successful FCM Setup:
```
🔔 FCM: Initializing FCM service...
✅ FCM: Service initialized successfully
🔔 FCM: Got token: [token]...
💾 FCM: Saving token to Firestore for user: [uid]
✅ FCM: Token saved to Firestore successfully
```

### Successful Notification Send:
```
🔔 LocationSharingService: Found 3 other logged-in users
🔍 LocationSharingService: User 1: John (uid1) - FCM Token: Present
📤 LocationSharingService: Attempting to send notification to John (uid1)
🔍 Push: Recipient uid1 - FCM Token: Present ([token]...)
📤 Push: Attempting to call Cloud Function sendLocationShareNotification...
✅ Push: Location share notification sent via Cloud Function
✅ LocationSharingService: Push notification sent to John
```

## Troubleshooting Checklist ✅

- [ ] App has notification permissions
- [ ] FCM service is initialized
- [ ] FCM token is generated
- [ ] FCM token is saved to Firestore
- [ ] User is marked as logged in
- [ ] Cloud Functions are deployed
- [ ] Other users have FCM tokens
- [ ] Other users are marked as logged in

## Next Steps 🚀

1. **Run the debug tools** to identify the specific issue
2. **Check console logs** for error messages
3. **Verify FCM token generation** and storage
4. **Deploy Cloud Functions** if not already done
5. **Test with multiple devices** to verify cross-device notifications

## Support 🆘

If issues persist:
1. Check the console logs for specific error messages
2. Verify Firebase project configuration
3. Check device notification settings
4. Test on different devices/emulators
5. Review Firestore security rules

## Quick Commands 💻

### Deploy Cloud Functions:
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Check Firebase Status:
```bash
firebase projects:list
firebase use [your-project-id]
firebase functions:list
```

### Test FCM Locally:
```bash
cd functions
npm run serve
```




