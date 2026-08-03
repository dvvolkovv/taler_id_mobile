class AppConfig {
  static const String _flavorEnv =
      String.fromEnvironment('FLAVOR', defaultValue: 'prod');

  // Set by the DO talerid build pipeline (ios-build.sh, Android build-droplet).
  // The talerid track is the only one that asserts this flag, so we treat it
  // as the authoritative flavor signal — older scripts in the pipeline pass
  // BASE_URL/WEB_URL/TALERID_PUBLIC but forget FLAVOR, which would otherwise
  // make this build identify as 'prod' (and render the "TEST" version prefix).
  static const bool _talerIdPublic =
      bool.fromEnvironment('TALERID_PUBLIC', defaultValue: false);

  static String get flavor => _talerIdPublic ? 'talerid' : _flavorEnv;

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
  //
  // Emptied on 2026-07-25 because calls broke: the wss URL is derived from the
  // active endpoint, and the edge's /livekit/ had no live upstream. That took
  // the whole API down with it for anyone behind CIS DPI — measured on such a
  // network 2026-08-03, api.talerid.io accepted the TCP connection and TLS
  // handshake and then never delivered a body (40s, no response), while both
  // edges answered in ~2s. Requests died on timeout inside a silent catch, so
  // the app looked healthy and simply did nothing.
  //
  // Restored, with media split out into [mediaCapableBaseUrls] so a media-dead
  // edge can no longer take the API with it.
  static const List<String> fallbackBaseUrls =
      baseUrl == 'https://api.talerid.io'
          ? ['https://ru.talerid.io', 'https://ru2.talerid.io']
          : <String>[];

  /// Endpoints whose `/livekit/` route actually reaches a live SFU, and so may
  /// carry a call.
  ///
  /// Deliberately not the same list as [fallbackBaseUrls]: ru2 relays the REST
  /// API fine but still answers 502 on /livekit/ (checked 2026-08-03), and
  /// routing a call there is what broke calls in the first place.
  static const List<String> mediaCapableBaseUrls =
      baseUrl == 'https://api.talerid.io'
          ? ['https://api.talerid.io', 'https://ru.talerid.io']
          : <String>[baseUrl];

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
