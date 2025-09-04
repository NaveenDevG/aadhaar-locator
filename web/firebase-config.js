// Firebase configuration for web
const firebaseConfig = {
  apiKey: "AIzaSyYourApiKeyHere1234567890",
  authDomain: "aadhaar-locator-app.firebaseapp.com",
  projectId: "aadhaar-locator-app",
  storageBucket: "aadhaar-locator-app.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef1234567890"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize Firebase services
const auth = firebase.auth();
const firestore = firebase.firestore();
const messaging = firebase.messaging();

