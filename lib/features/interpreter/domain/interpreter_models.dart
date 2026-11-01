import 'package:equatable/equatable.dart';

/// One entry of `GET /interpreter/languages`.
class InterpreterLanguage extends Equatable {
  final String code;
  final String name;

  const InterpreterLanguage({required this.code, required this.name});

  factory InterpreterLanguage.fromJson(Map<String, dynamic> json) =>
      InterpreterLanguage(
        code: json['code'] as String,
        name: json['name'] as String,
      );

  @override
  List<Object?> get props => [code, name];
}

/// `GET /interpreter/languages` response — the feature switch plus the
/// supported language list.
class InterpreterCatalog extends Equatable {
  final bool enabled;
  final List<InterpreterLanguage> languages;

  const InterpreterCatalog({required this.enabled, required this.languages});

  factory InterpreterCatalog.fromJson(Map<String, dynamic> json) =>
      InterpreterCatalog(
        enabled: json['enabled'] as bool,
        languages: (json['languages'] as List)
            .map((e) => InterpreterLanguage.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList(),
      );

  @override
  List<Object?> get props => [enabled, languages];
}

/// Which translation engine a direction runs on, per the join answer's
/// `directions`.
enum InterpreterEngine { simultaneous, phrase }

/// Unknown engine strings fall back to [InterpreterEngine.phrase]: it is the
/// more conservative UI (a "phrase" badge, no streamed captions) rather than
/// silently promising simultaneous translation the server didn't commit to.
InterpreterEngine interpreterEngineFromJson(String raw) => switch (raw) {
      'simultaneous' => InterpreterEngine.simultaneous,
      'phrase' => InterpreterEngine.phrase,
      _ => InterpreterEngine.phrase,
    };

class InterpreterDirections extends Equatable {
  final InterpreterEngine toMe;
  final InterpreterEngine fromMe;

  const InterpreterDirections({required this.toMe, required this.fromMe});

  factory InterpreterDirections.fromJson(Map<String, dynamic> json) =>
      InterpreterDirections(
        toMe: interpreterEngineFromJson(json['toMe'] as String),
        fromMe: interpreterEngineFromJson(json['fromMe'] as String),
      );

  @override
  List<Object?> get props => [toMe, fromMe];
}

class InterpreterPartner extends Equatable {
  final String? firstName;
  final String? avatarUrl;
  final String lang;

  const InterpreterPartner(
      {this.firstName, this.avatarUrl, required this.lang});

  factory InterpreterPartner.fromJson(Map<String, dynamic> json) =>
      InterpreterPartner(
        firstName: json['firstName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        lang: json['lang'] as String,
      );

  @override
  List<Object?> get props => [firstName, avatarUrl, lang];
}

/// `POST /interpreter/sessions` response — host (A) side of a fresh session.
class HostedSession extends Equatable {
  final String sessionId;
  final String code;
  final DateTime expiresAt;
  final String roomName;
  final String token;
  final String livekitWsUrl;

  const HostedSession({
    required this.sessionId,
    required this.code,
    required this.expiresAt,
    required this.roomName,
    required this.token,
    required this.livekitWsUrl,
  });

  factory HostedSession.fromJson(Map<String, dynamic> json) => HostedSession(
        sessionId: json['sessionId'] as String,
        code: json['code'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        roomName: json['roomName'] as String,
        token: json['token'] as String,
        livekitWsUrl: json['livekitWsUrl'] as String,
      );

  @override
  List<Object?> get props =>
      [sessionId, code, expiresAt, roomName, token, livekitWsUrl];
}

/// `POST /interpreter/sessions/:id/code` response — a replacement QR code
/// for a still-waiting session.
class NewCode extends Equatable {
  final String code;
  final DateTime expiresAt;

  const NewCode({required this.code, required this.expiresAt});

  factory NewCode.fromJson(Map<String, dynamic> json) => NewCode(
        code: json['code'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );

  @override
  List<Object?> get props => [code, expiresAt];
}

/// `POST /interpreter/sessions/join` response — guest (B) side.
class JoinedSession extends Equatable {
  final String sessionId;
  final String roomName;
  final String token;
  final String livekitWsUrl;
  final InterpreterPartner partner;
  final InterpreterDirections directions;

  const JoinedSession({
    required this.sessionId,
    required this.roomName,
    required this.token,
    required this.livekitWsUrl,
    required this.partner,
    required this.directions,
  });

  factory JoinedSession.fromJson(Map<String, dynamic> json) => JoinedSession(
        sessionId: json['sessionId'] as String,
        roomName: json['roomName'] as String,
        token: json['token'] as String,
        livekitWsUrl: json['livekitWsUrl'] as String,
        partner: InterpreterPartner.fromJson(
          Map<String, dynamic>.from(json['partner'] as Map),
        ),
        directions: InterpreterDirections.fromJson(
          Map<String, dynamic>.from(json['directions'] as Map),
        ),
      );

  @override
  List<Object?> get props =>
      [sessionId, roomName, token, livekitWsUrl, partner, directions];
}

enum InterpreterStatus { waiting, active, ended }

/// An unrecognised status is treated as [InterpreterStatus.ended]: a session
/// the client can't name a known state for is safer shown as "over" than
/// left spinning in a state the UI doesn't know how to render.
InterpreterStatus interpreterStatusFromJson(String raw) => switch (raw) {
      'waiting' => InterpreterStatus.waiting,
      'active' => InterpreterStatus.active,
      'ended' => InterpreterStatus.ended,
      _ => InterpreterStatus.ended,
    };

enum InterpreterEndReason {
  hangup,
  partnerLeft,
  expired,
  translationFailed,
  agentLost,
  noFunds,
  maxDuration,
}

/// `endReason` is optional on the wire; an unrecognised non-null value maps
/// to `null` rather than throwing or guessing — the ended screen already
/// handles a missing reason with generic wording.
InterpreterEndReason? interpreterEndReasonFromJson(String? raw) {
  switch (raw) {
    case 'hangup':
      return InterpreterEndReason.hangup;
    case 'partner_left':
      return InterpreterEndReason.partnerLeft;
    case 'expired':
      return InterpreterEndReason.expired;
    case 'translation_failed':
      return InterpreterEndReason.translationFailed;
    case 'agent_lost':
      return InterpreterEndReason.agentLost;
    case 'no_funds':
      return InterpreterEndReason.noFunds;
    case 'max_duration':
      return InterpreterEndReason.maxDuration;
    default:
      return null;
  }
}

/// `GET /interpreter/sessions/:id` response.
class SessionView extends Equatable {
  final InterpreterStatus status;
  final InterpreterEndReason? endReason;
  final InterpreterPartner? partner;
  final InterpreterDirections? directions;
  final DateTime? startedAt;
  final String? spentPlanck;

  const SessionView({
    required this.status,
    this.endReason,
    this.partner,
    this.directions,
    this.startedAt,
    this.spentPlanck,
  });

  factory SessionView.fromJson(Map<String, dynamic> json) {
    final partnerJson = json['partner'];
    final directionsJson = json['directions'];
    final startedAtRaw = json['startedAt'] as String?;
    return SessionView(
      status: interpreterStatusFromJson(json['status'] as String),
      endReason: interpreterEndReasonFromJson(json['endReason'] as String?),
      partner: partnerJson == null
          ? null
          : InterpreterPartner.fromJson(
              Map<String, dynamic>.from(partnerJson as Map),
            ),
      directions: directionsJson == null
          ? null
          : InterpreterDirections.fromJson(
              Map<String, dynamic>.from(directionsJson as Map),
            ),
      startedAt: startedAtRaw == null ? null : DateTime.parse(startedAtRaw),
      spentPlanck: json['spentPlanck'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [status, endReason, partner, directions, startedAt, spentPlanck];
}
