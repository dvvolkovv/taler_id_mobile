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
}
