class AppConfig {
  static const String flavor =
      String.fromEnvironment('FLAVOR', defaultValue: 'prod');

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://id.taler.tirol',
  );

  // Public web domain for share links, OAuth fallback, deep links (NOT the API host).
  static const String webUrl = String.fromEnvironment(
    'WEB_URL',
    defaultValue: 'https://id.taler.tirol',
  );

  // CIS availability: when the primary DO backend (api.talerid.io) is DPI-blocked
  // for end-users, the app fails over to these Russian-IP Selectel edges, which
  // relay to the same backend. Only the public `talerid` build (api.talerid.io)
  // has edges; dev/aeza builds get none (failover is then inert). See
  // EndpointService + infra/do/provision/selectel-ru-edge.sh.
  static const List<String> fallbackBaseUrls =
      baseUrl == 'https://api.talerid.io'
          ? ['https://ru.talerid.io', 'https://ru2.talerid.io']
          : <String>[];

  static bool get isDev => flavor == 'dev';
  static bool get isProd => flavor == 'prod';
  static bool get isTalerid => flavor == 'talerid';

  /// Short label shown in the Settings screen in front of the version
  /// number — mirrors the app-icon name prefix so the user can tell at a
  /// glance which build (DEV/TEST/PROD) they are on without launching
  /// the app. Empty for the canonical talerid (DO) PROD flavor.
  static String get versionPrefix {
    switch (flavor) {
      case 'dev':
        return 'DEV';
      case 'prod':
        return 'TEST';
      case 'talerid':
        return '';
      default:
        return '';
    }
  }
}
