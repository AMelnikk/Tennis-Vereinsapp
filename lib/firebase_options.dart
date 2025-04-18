// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyCV6bEMtuX4q-s4YpHStlU3kNCMj11T4Dk',
    appId: '1:1050815457795:web:2d0bc6f9b80793f6e37c36',
    messagingSenderId: '1050815457795',
    projectId: 'db-teg',
    authDomain: 'db-teg.firebaseapp.com',
    databaseURL: 'https://db-teg-default-rtdb.firebaseio.com',
    storageBucket: 'db-teg.firebasestorage.app',
    measurementId: 'G-LNJY8VGKTG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAskOwP-rWTjHIl1b31_iBWQWsRWUEm2Ds',
    appId: '1:1050815457795:android:ea64d2287d19e410e37c36',
    messagingSenderId: '1050815457795',
    projectId: 'db-teg',
    databaseURL: 'https://db-teg-default-rtdb.firebaseio.com',
    storageBucket: 'db-teg.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDeKsRsXr7yuPMdqOn4DbRTPAPBKrGObSg',
    appId: '1:1050815457795:ios:5b192a80fab9f613e37c36',
    messagingSenderId: '1050815457795',
    projectId: 'db-teg',
    databaseURL: 'https://db-teg-default-rtdb.firebaseio.com',
    storageBucket: 'db-teg.firebasestorage.app',
    iosBundleId: 'com.example.vereinApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDeKsRsXr7yuPMdqOn4DbRTPAPBKrGObSg',
    appId: '1:1050815457795:ios:5b192a80fab9f613e37c36',
    messagingSenderId: '1050815457795',
    projectId: 'db-teg',
    databaseURL: 'https://db-teg-default-rtdb.firebaseio.com',
    storageBucket: 'db-teg.firebasestorage.app',
    iosBundleId: 'com.example.vereinApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCV6bEMtuX4q-s4YpHStlU3kNCMj11T4Dk',
    appId: '1:1050815457795:web:c890b1147414de24e37c36',
    messagingSenderId: '1050815457795',
    projectId: 'db-teg',
    authDomain: 'db-teg.firebaseapp.com',
    databaseURL: 'https://db-teg-default-rtdb.firebaseio.com',
    storageBucket: 'db-teg.firebasestorage.app',
    measurementId: 'G-S11MZSRJNW',
  );
}
