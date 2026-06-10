import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not configured for this platform.');
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDty0zW6nV-NhavO1CtqBpSSHTPII-jpcM',
    appId: '1:874666026525:android:1ca4e239d25e5d8fef08f4',
    messagingSenderId: '874666026525',
    projectId: 'naql-bc9e3',
    databaseURL: 'https://naql-bc9e3-default-rtdb.firebaseio.com',
    storageBucket: 'naql-bc9e3.firebasestorage.app',
  );

  // iOS config — add your GoogleService-Info.plist values here
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDty0zW6nV-NhavO1CtqBpSSHTPII-jpcM',
    appId: '1:874666026525:ios:000000000000000000000000',
    messagingSenderId: '874666026525',
    projectId: 'naql-bc9e3',
    databaseURL: 'https://naql-bc9e3-default-rtdb.firebaseio.com',
    storageBucket: 'naql-bc9e3.firebasestorage.app',
    iosBundleId: 'com.naql.naqlApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDty0zW6nV-NhavO1CtqBpSSHTPII-jpcM',
    appId: '1:874666026525:web:000000000000000000000000',
    messagingSenderId: '874666026525',
    projectId: 'naql-bc9e3',
    authDomain: 'naql-bc9e3.firebaseapp.com',
    databaseURL: 'https://naql-bc9e3-default-rtdb.firebaseio.com',
    storageBucket: 'naql-bc9e3.firebasestorage.app',
  );
}
