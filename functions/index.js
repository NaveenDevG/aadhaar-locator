const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Send location share notification to a specific user
 */
exports.sendLocationShareNotification = functions.https.onCall(async (data, context) => {
  try {
    const { recipientToken, senderName, latitude, longitude, senderUid } = data;

    if (!recipientToken || !senderName || !latitude || !longitude) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
    }

    const message = {
      token: recipientToken,
      notification: {
        title: `📍 ${senderName} shared location`,
        body: `${senderName} shared their location with you`,
      },
      data: {
        type: 'location_share',
        senderName: senderName,
        senderUid: senderUid || '',
        latitude: latitude.toString(),
        longitude: longitude.toString(),
        timestamp: new Date().toISOString(),
      },
      android: {
        priority: 'high',
        notification: {
          icon: 'ic_notification',
          color: '#2196F3',
        },
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'default',
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending message:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});

/**
 * Send notification to multiple users
 */
exports.sendNotificationToMultipleUsers = functions.https.onCall(async (data, context) => {
  try {
    const { recipientTokens, title, body, data: notificationData } = data;

    if (!recipientTokens || !Array.isArray(recipientTokens) || recipientTokens.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid recipient tokens');
    }

    if (!title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Title and body are required');
    }

    const message = {
      tokens: recipientTokens,
      notification: {
        title: title,
        body: body,
      },
      data: notificationData || {},
      android: {
        priority: 'high',
        notification: {
          icon: 'ic_notification',
          color: '#2196F3',
        },
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'default',
          },
        },
      },
    };

    const response = await admin.messaging().sendMulticast(message);
    console.log('Successfully sent multicast message:', response);
    
    return { 
      success: true, 
      successCount: response.successCount,
      failureCount: response.failureCount,
      responses: response.responses
    };
  } catch (error) {
    console.error('Error sending multicast message:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notifications');
  }
});

/**
 * Send emergency notification to all users
 */
exports.sendEmergencyNotification = functions.https.onCall(async (data, context) => {
  try {
    const { recipientTokens, title, body, emergencyType, data: notificationData } = data;

    if (!recipientTokens || !Array.isArray(recipientTokens) || recipientTokens.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid recipient tokens');
    }

    if (!title || !body || !emergencyType) {
      throw new functions.https.HttpsError('invalid-argument', 'Title, body, and emergency type are required');
    }

    const message = {
      tokens: recipientTokens,
      notification: {
        title: `🚨 ${title}`,
        body: body,
      },
      data: {
        type: 'emergency',
        emergencyType: emergencyType,
        ...notificationData,
        timestamp: new Date().toISOString(),
      },
      android: {
        priority: 'high',
        notification: {
          icon: 'ic_emergency',
          color: '#F44336',
          sound: 'emergency_sound',
        },
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'emergency_sound.aiff',
            category: 'EMERGENCY',
          },
        },
      },
    };

    const response = await admin.messaging().sendMulticast(message);
    console.log('Successfully sent emergency notification:', response);
    
    return { 
      success: true, 
      successCount: response.successCount,
      failureCount: response.failureCount,
      responses: response.responses
    };
  } catch (error) {
    console.error('Error sending emergency notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send emergency notification');
  }
});

/**
 * Send test notification
 */
exports.sendTestNotification = functions.https.onCall(async (data, context) => {
  try {
    const { recipientToken, title, body, data: notificationData } = data;

    if (!recipientToken) {
      throw new functions.https.HttpsError('invalid-argument', 'Recipient token is required');
    }

    const message = {
      token: recipientToken,
      notification: {
        title: title || 'Test Notification',
        body: body || 'This is a test notification from Firebase Cloud Functions',
      },
      data: {
        type: 'test',
        timestamp: new Date().toISOString(),
        ...notificationData,
      },
      android: {
        priority: 'high',
        notification: {
          icon: 'ic_notification',
          color: '#4CAF50',
        },
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'default',
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log('Successfully sent test message:', response);
    
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending test message:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send test notification');
  }
});


