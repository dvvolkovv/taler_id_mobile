import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'core/config/app_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web is not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNTilLiCbGOAIFfsivLmL9NLCVe9bGifo',
    appId: '1:337152405350:android:29d8c7c9fa75c9dd65a2a7',
    messagingSenderId: '337152405350',
    projectId: 'talerid-afd44',
    storageBucket: 'talerid-afd44.firebasestorage.app',
  );

  static FirebaseOptions get ios {
    if (AppConfig.isDev) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyAuMsMgk63qIMGpQWN8iSRq2HXclZfZA48',
        appId: '1:337152405350:ios:9687f20510593a6565a2a7',
        messagingSenderId: '337152405350',
        projectId: 'talerid-afd44',
        storageBucket: 'talerid-afd44.firebasestorage.app',
        iosBundleId: 'tirol.taler.talerIdMobile.dev',
      );
    }
    return const FirebaseOptions(
      apiKey: 'AIzaSyAuMsMgk63qIMGpQWN8iSRq2HXclZfZA48',
      appId: '1:337152405350:ios:b6d0f85eae1e517365a2a7',
      messagingSenderId: '337152405350',
      projectId: 'talerid-afd44',
      storageBucket: 'talerid-afd44.firebasestorage.app',
      iosBundleId: 'tirol.taler.talerIdMobile',
    );
  }
}
