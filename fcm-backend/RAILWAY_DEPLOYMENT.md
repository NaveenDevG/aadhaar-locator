# 🚀 Railway Deployment Guide

## ✅ **What This Does**

Deploy your FCM backend to Railway for free, reliable push notification service.

## 🚀 **Deployment Steps**

### **Step 1: Get Service Account Key**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `aadhaarlocator`
3. Go to **Project Settings** → **Service Accounts**
4. Click **"Generate new private key"**
5. Download the JSON file

### **Step 2: Deploy to Railway**

1. **Go to**: https://railway.app
2. **Sign up/Login** with GitHub
3. **Click**: "New Project"
4. **Select**: "Deploy from GitHub repo"
5. **Choose**: Your `aadhaar_locator` repository
6. **Select**: `fcm-backend` folder as root directory

### **Step 3: Set Environment Variables**

In Railway dashboard, go to your project → Variables tab and add:

```
FIREBASE_PROJECT_ID=aadhaarlocator
FIREBASE_PRIVATE_KEY_ID=your_private_key_id_here
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@aadhaarlocator.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=your_client_id_here
```

### **Step 4: Update Flutter App**

Replace `localhost:3000` with your Railway URL in:
- `lib/features/notifications/services/push_notification_service.dart`
- `lib/features/notifications/services/backend_fcm_service.dart`

## 🎯 **Benefits**

- ✅ **Free hosting** (Railway free tier)
- ✅ **Always online** (no local server needed)
- ✅ **HTTPS enabled** (secure communication)
- ✅ **Auto-deploy** from GitHub
- ✅ **Environment variables** (secure credential storage)

## 📱 **Testing**

After deployment, test with:

```bash
curl https://your-railway-url.railway.app/
curl -X POST https://your-railway-url.railway.app/sendPush \
  -H "Content-Type: application/json" \
  -d '{"token":"YOUR_FCM_TOKEN","title":"Test","body":"Hello from Railway!"}'
```

## 🔧 **Troubleshooting**

- **Check Railway logs** for deployment issues
- **Verify environment variables** are set correctly
- **Test endpoints** with curl commands
- **Check Firebase Console** for service account permissions
