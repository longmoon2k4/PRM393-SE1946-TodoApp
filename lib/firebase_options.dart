// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyAl2GpaNPvAiux2f7E35Q3UC05a9Ovx_68',
    appId: '1:387812790123:web:5a726aaba4f19d34a0462e',
    messagingSenderId: '387812790123',
    projectId: 'todo-app-prm393',
    authDomain: 'todo-app-prm393.firebaseapp.com',
    storageBucket: 'todo-app-prm393.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDthTYBHOSQnXq1WsI8-m5W2AAITEGD-MA',
    appId: '1:387812790123:android:d291f28162f3ef96a0462e',
    messagingSenderId: '387812790123',
    projectId: 'todo-app-prm393',
    storageBucket: 'todo-app-prm393.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDDc_J0ktQUtcsJtkMnnzMBKHrLV_HhXj0',
    appId: '1:387812790123:ios:9405c96b820ffe37a0462e',
    messagingSenderId: '387812790123',
    projectId: 'todo-app-prm393',
    storageBucket: 'todo-app-prm393.firebasestorage.app',
    iosBundleId: 'com.example.todoApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDDc_J0ktQUtcsJtkMnnzMBKHrLV_HhXj0',
    appId: '1:387812790123:ios:9405c96b820ffe37a0462e',
    messagingSenderId: '387812790123',
    projectId: 'todo-app-prm393',
    storageBucket: 'todo-app-prm393.firebasestorage.app',
    iosBundleId: 'com.example.todoApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAl2GpaNPvAiux2f7E35Q3UC05a9Ovx_68',
    appId: '1:387812790123:web:d63a9eb5835a97b1a0462e',
    messagingSenderId: '387812790123',
    projectId: 'todo-app-prm393',
    authDomain: 'todo-app-prm393.firebaseapp.com',
    storageBucket: 'todo-app-prm393.firebasestorage.app',
  );
}
