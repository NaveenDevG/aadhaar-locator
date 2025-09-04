# FCM Backend - Local Development

A lightweight Node.js backend for sending Firebase Cloud Messaging (FCM) push notifications using the HTTP v1 API, for local development and testing.

## 🚀 Features

- ✅ Uses FCM HTTP v1 API (modern, supported)
- ✅ No Firebase Blaze plan required
- ✅ Firebase Admin SDK integration
- ✅ OAuth2 authentication handled automatically
- ✅ Support for single and multiple device notifications
- ✅ Simple REST API
- ✅ Local development only

## 📋 Prerequisites

- Node.js 18+ installed
- Firebase project with service account
- FCM tokens from your Flutter app

## 🛠️ Local Setup Instructions

### 1. Get Your Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Project Settings** → **Service Accounts**
4. Click **"Generate new private key"**
5. Download the JSON file

### 2. Local Development Setup

```bash
# Navigate to the backend directory
cd fcm-backend

# Install dependencies
npm install

# Copy your service account JSON to the project root
# Rename it to: service-account.json

# Start the server
npm start
```

## 📡 API Endpoints

### Health Check
```
GET /
```

### Send Single Notification
```
POST /sendPush
Content-Type: application/json

{
  "token": "DEVICE_FCM_TOKEN",
  "title": "Hello",
  "body": "Test notification",
  "data": {
    "custom_key": "custom_value"
  }
}
```

### Send to Multiple Devices
```
POST /sendPushToMultiple
Content-Type: application/json

{
  "tokens": ["TOKEN1", "TOKEN2", "TOKEN3"],
  "title": "Hello Everyone",
  "body": "Group notification",
  "data": {
    "type": "group_message"
  }
}
```

### Test Endpoint
```
GET /test
```

## 🧪 Testing with cURL

### Test Health Check
```bash
curl http://localhost:3000/
```

### Send Test Notification
```bash
curl -X POST http://localhost:3000/sendPush \
  -H "Content-Type: application/json" \
  -d '{
    "token": "YOUR_FCM_TOKEN_HERE",
    "title": "Test Notification",
    "body": "This is a test from the backend"
  }'
```

### Send to Multiple Devices
```bash
curl -X POST http://localhost:3000/sendPushToMultiple \
  -H "Content-Type: application/json" \
  -d '{
    "tokens": ["TOKEN1", "TOKEN2"],
    "title": "Group Test",
    "body": "Testing multiple devices"
  }'
```

## 🔒 Security Notes

- **Never commit service-account.json to Git**
- The service account key should only be on your local machine
- Your Flutter app will call this local backend, not Firebase directly

## 📱 Flutter Integration

Update your Flutter app to call this local backend:

```dart
// Replace your current FCM service with HTTP calls to this backend
final response = await http.post(
  Uri.parse('http://localhost:3000/sendPush'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'token': fcmToken,
    'title': title,
    'body': body,
    'data': data,
  }),
);
```

## 🎯 Benefits

- ✅ **No Blaze Plan Required** - Works with free Firebase plan
- ✅ **Modern FCM API** - Uses HTTP v1 API
- ✅ **Automatic OAuth2** - Firebase Admin SDK handles authentication
- ✅ **Local Development** - Perfect for testing and development
- ✅ **Simple API** - Easy to integrate with Flutter
- ✅ **Secure** - Service account stays on your local machine

## 🚨 Important

This backend handles the OAuth2 authentication automatically using Firebase Admin SDK, so you don't need to worry about JWT signing or access tokens!
