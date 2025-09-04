const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin SDK
let serviceAccount;
try {
  // Try to load from environment variable (for production/Railway)
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    console.log('✅ Using service account from environment variable');
  } else if (process.env.FIREBASE_PRIVATE_KEY) {
    // Alternative: individual environment variables
    serviceAccount = {
      type: "service_account",
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${encodeURIComponent(process.env.FIREBASE_CLIENT_EMAIL)}`,
      universe_domain: "googleapis.com"
    };
    console.log('✅ Using service account from individual environment variables');
  } else {
    // Fallback to local file (for development)
    serviceAccount = require('./service-account.json');
    console.log('✅ Using service account from local file');
  }
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id
  });
  
  console.log('✅ Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
  process.exit(1);
}

// Health check endpoint
app.get('/', (req, res) => {
  res.json({
    status: 'OK',
    message: 'FCM Backend is running',
    timestamp: new Date().toISOString(),
    projectId: serviceAccount.project_id
  });
});

// Send push notification endpoint
app.post('/sendPush', async (req, res) => {
  try {
    const { token, title, body, data } = req.body;
    
    // Validate required fields
    if (!token) {
      return res.status(400).json({
        success: false,
        error: 'FCM token is required'
      });
    }
    
    if (!title || !body) {
      return res.status(400).json({
        success: false,
        error: 'Title and body are required'
      });
    }
    
    console.log(`📤 Sending notification to token: ${token.substring(0, 20)}...`);
    
    // Create the message
    const message = {
      token: token,
      notification: {
        title: title,
        body: body
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          icon: 'ic_notification',
          color: '#2196F3'
        }
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'default'
          }
        }
      }
    };
    
    // Send the message
    const response = await admin.messaging().send(message);
    
    console.log('✅ Notification sent successfully:', response);
    
    res.json({
      success: true,
      messageId: response,
      message: 'Notification sent successfully'
    });
    
  } catch (error) {
    console.error('❌ Failed to send notification:', error);
    
    res.status(500).json({
      success: false,
      error: error.message,
      code: error.code || 'UNKNOWN_ERROR'
    });
  }
});

// Send to multiple tokens endpoint
app.post('/sendPushToMultiple', async (req, res) => {
  try {
    const { tokens, title, body, data } = req.body;
    
    // Validate required fields
    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Tokens array is required and must not be empty'
      });
    }
    
    if (!title || !body) {
      return res.status(400).json({
        success: false,
        error: 'Title and body are required'
      });
    }
    
    console.log(`📤 Sending notification to ${tokens.length} tokens`);
    
    // Create the message
    const message = {
      tokens: tokens,
      notification: {
        title: title,
        body: body
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          icon: 'ic_notification',
          color: '#2196F3'
        }
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'default'
          }
        }
      }
    };
    
    // Send the message
    const response = await admin.messaging().sendMulticast(message);
    
    console.log(`✅ Notification sent to ${response.successCount}/${tokens.length} devices`);
    
    res.json({
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      totalCount: tokens.length,
      message: `Notification sent to ${response.successCount}/${tokens.length} devices`
    });
    
  } catch (error) {
    console.error('❌ Failed to send multicast notification:', error);
    
    res.status(500).json({
      success: false,
      error: error.message,
      code: error.code || 'UNKNOWN_ERROR'
    });
  }
});

// Test endpoint
app.get('/test', async (req, res) => {
  try {
    // Test Firebase Admin SDK
    const app = admin.app();
    const projectId = app.options.projectId;
    
    res.json({
      success: true,
      message: 'Backend is working correctly',
      projectId: projectId,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 FCM Backend server running on port ${PORT}`);
  console.log(`📱 Project ID: ${serviceAccount.project_id}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/`);
  console.log(`📤 Send notification: POST http://localhost:${PORT}/sendPush`);
});

module.exports = app;

