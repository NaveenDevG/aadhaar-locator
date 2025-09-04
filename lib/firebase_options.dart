import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA3xmnjx5mEKDSCCxQm9AthWz5diUSRXQk',
    appId: '1:1072240028077:web:a065c1ff7cc8e3b6de5924',
    messagingSenderId: '1072240028077',
    projectId: 'aadhaarlocator',
    authDomain: 'aadhaarlocator.firebaseapp.com',
    storageBucket: 'aadhaarlocator.firebasestorage.app',
    measurementId: 'G-XXXXXXXXXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA3xmnjx5mEKDSCCxQm9AthWz5diUSRXQk',
    appId: '1:1072240028077:android:a065c1ff7cc8e3b6de5924',
    messagingSenderId: '1072240028077',
    projectId: 'aadhaarlocator',
    storageBucket: 'aadhaarlocator.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA3xmnjx5mEKDSCCxQm9AthWz5diUSRXQk',
    appId: '1:1072240028077:ios:a065c1ff7cc8e3b6de5924',
    messagingSenderId: '1072240028077',
    projectId: 'aadhaarlocator',
    storageBucket: 'aadhaarlocator.firebasestorage.app',
    iosBundleId: 'com.apple.aadhaarlocator.aadhaarLocator',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA3xmnjx5mEKDSCCxQm9AthWz5diUSRXQk',
    appId: '1:1072240028077:ios:a065c1ff7cc8e3b6de5924',
    messagingSenderId: '1072240028077',
    projectId: 'aadhaarlocator',
    storageBucket: 'aadhaarlocator.firebasestorage.app',
    iosBundleId: 'com.apple.aadhaarlocator.aadhaarLocator',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA3xmnjx5mEKDSCCxQm9AthWz5diUSRXQk',
    appId: '1:1072240028077:web:a065c1ff7cc8e3b6de5924',
    messagingSenderId: '1072240028077',
    projectId: 'aadhaarlocator',
    authDomain: 'aadhaarlocator.firebaseapp.com',
    storageBucket: 'aadhaarlocator.firebasestorage.app',
  );
}
