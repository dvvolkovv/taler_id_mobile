import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'core/config/app_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web is not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _taleridPublic ? androidTalerid : android;
      case TargetPlatform.iOS:
        return _taleridPublic ? iosTalerid : ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Public DigitalOcean app (io.talerid.app), selected via --dart-define=TALERID_PUBLIC=true.
  static const bool _taleridPublic = bool.fromEnvironment('TALERID_PUBLIC');

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNTilLiCbGOAIFfsivLmL9NLCVe9bGifo',
    appId: '1:337152405350:android:29d8c7c9fa75c9dd65a2a7',
    messagingSenderId: '337152405350',
    projectId: 'talerid-afd44',
    storageBucket: 'talerid-afd44.firebasestorage.app',
  );

  static const FirebaseOptions androidTalerid = FirebaseOptions(
    apiKey: 'AIzaSyCNTilLiCbGOAIFfsivLmL9NLCVe9bGifo',
    appId: '1:337152405350:android:3a74e7f11285486265a2a7',
    messagingSenderId: '337152405350',
    projectId: 'talerid-afd44',
    storageBucket: 'talerid-afd44.firebasestorage.app',
  );

  // Public DigitalOcean iOS app (io.talerid.app) in the talerid-afd44 project.
  // Selected only when TALERID_PUBLIC=true, so the aeza dev/prod iOS config below
  // (tirol.taler.talerIdMobile) is left untouched — both environments stay supported.
  static const FirebaseOptions iosTalerid = FirebaseOptions(
    apiKey: 'AIzaSyAuMsMgk63qIMGpQWN8iSRq2HXclZfZA48',
    appId: '1:337152405350:ios:dababd62bfbd70c365a2a7',
    messagingSenderId: '337152405350',
    projectId: 'talerid-afd44',
    storageBucket: 'talerid-afd44.firebasestorage.app',
    iosBundleId: 'io.talerid.app',
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
