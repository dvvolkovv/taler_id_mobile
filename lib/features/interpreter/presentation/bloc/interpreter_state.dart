import 'package:equatable/equatable.dart';

import '../../domain/interpreter_error.dart';
import '../../domain/interpreter_models.dart';
import '../../room/caption_lines.dart';

/// Pending action a still-open [InterpreterNeedVoicePrint] gate will resume
/// once the owner finishes (or cancels) recording a voice print.
enum InterpreterPendingAction { host, join }

/// How a would-be host/guest is working through the start flow, shown while
/// a REST round-trip to create or join a session is in flight.
enum InterpreterWorkKind { creating, joining }

/// Health of the call as the UI reports it. A reconnecting/healthy LiveKit
/// room (the controller's own `Connection` update) and a
/// reconnecting/healthy/failed translation socket on the agent side (a
/// `StatusSignal`) both funnel into this one field — either kind of trouble
/// reads the same to the person holding the phone.
enum InterpreterLinkState { reconnecting, ok, failed }

sealed class InterpreterState extends Equatable {
  const InterpreterState();
}

class InterpreterLoading extends InterpreterState {
  const InterpreterLoading();
  @override
  List<Object?> get props => const [];
}

/// `GET /interpreter/languages` answered `enabled: false`.
class InterpreterUnavailable extends InterpreterState {
  const InterpreterUnavailable();
  @override
  List<Object?> get props => const [];
}

/// The owner has no usable voice print. [then]/[code] say what to resume
/// once the enrollment sheet reports back via `VoicePrintResult`; the
/// Choosing state to fall back to on cancel is tracked internally by the
/// bloc, not carried on this state.
class InterpreterNeedVoicePrint extends InterpreterState {
  final InterpreterPendingAction then;
  final String? code;

  const InterpreterNeedVoicePrint({required this.then, this.code});

  @override
  List<Object?> get props => [then, code];
}

class InterpreterChoosing extends InterpreterState {
  final InterpreterCatalog catalog;
  final String myLang;
  final String? joinCode;

  const InterpreterChoosing({
    required this.catalog,
    required this.myLang,
    this.joinCode,
  });

  InterpreterChoosing copyWith({String? myLang}) => InterpreterChoosing(
        catalog: catalog,
        myLang: myLang ?? this.myLang,
        joinCode: joinCode,
      );

  @override
  List<Object?> get props => [catalog, myLang, joinCode];
}

/// A `create`/`join` REST round-trip is in flight.
class InterpreterWorking extends InterpreterState {
  final InterpreterWorkKind kind;
  const InterpreterWorking(this.kind);
  @override
  List<Object?> get props => [kind];
}

/// Host (A), connected and waiting for a guest to scan [code].
class InterpreterHosting extends InterpreterState {
  final HostedSession session;
  final String code;
  final DateTime expiresAt;
  final String myLang;

  const InterpreterHosting({
    required this.session,
    required this.code,
    required this.expiresAt,
    required this.myLang,
  });

  InterpreterHosting copyWith({String? code, DateTime? expiresAt}) =>
      InterpreterHosting(
        session: session,
        code: code ?? this.code,
        expiresAt: expiresAt ?? this.expiresAt,
        myLang: myLang,
      );

  @override
  List<Object?> get props => [session, code, expiresAt, myLang];
}

/// The conversation itself, for both host and guest.
class InterpreterActive extends InterpreterState {
  final bool isHost;
  final String myLang;
  final InterpreterPartner partner;
  final InterpreterDirections directions;
  final CaptionLines captions;
  final bool partnerSpeaking;
  final bool meSpeaking;
  final bool agentPresent;
  final InterpreterLinkState connection;
  final bool micOn;
  final DateTime startedAt;
  final String? spentPlanck;
  final int _revision;

  // Not `const`-able: `captions` is a mutable accumulator, not a value.
  // ignore: prefer_const_constructors_in_immutables
  InterpreterActive({
    required this.isHost,
    required this.myLang,
    required this.partner,
    required this.directions,
    required this.captions,
    required this.partnerSpeaking,
    required this.meSpeaking,
    required this.agentPresent,
    required this.connection,
    required this.micOn,
    required this.startedAt,
    this.spentPlanck,
    int revision = 0,
  }) : _revision = revision;

  /// [captions] is the very same mutable accumulator on every copy — new
  /// signals are appended to it in place by the bloc rather than rebuilt —
  /// so it is deliberately left out of [props]: comparing it would always
  /// see the identical object. [_revision] is bumped on every copy instead,
  /// so each update is a distinct state Equatable will actually deliver to
  /// listeners, including a caption-only one that touches no other field.
  InterpreterActive copyWith({
    InterpreterPartner? partner,
    InterpreterDirections? directions,
    bool? partnerSpeaking,
    bool? meSpeaking,
    bool? agentPresent,
    InterpreterLinkState? connection,
    bool? micOn,
    String? spentPlanck,
  }) =>
      InterpreterActive(
        isHost: isHost,
        myLang: myLang,
        partner: partner ?? this.partner,
        directions: directions ?? this.directions,
        captions: captions,
        partnerSpeaking: partnerSpeaking ?? this.partnerSpeaking,
        meSpeaking: meSpeaking ?? this.meSpeaking,
        agentPresent: agentPresent ?? this.agentPresent,
        connection: connection ?? this.connection,
        micOn: micOn ?? this.micOn,
        startedAt: startedAt,
        spentPlanck: spentPlanck ?? this.spentPlanck,
        revision: _revision + 1,
      );

  @override
  List<Object?> get props => [
        isHost,
        myLang,
        partner,
        directions,
        partnerSpeaking,
        meSpeaking,
        agentPresent,
        connection,
        micOn,
        startedAt,
        spentPlanck,
        _revision,
      ];
}

class InterpreterEnded extends InterpreterState {
  final InterpreterEndReason? reason;
  final Duration? duration;
  final String? spentPlanck;
  final bool isHost;

  const InterpreterEnded({
    this.reason,
    this.duration,
    this.spentPlanck,
    required this.isHost,
  });

  @override
  List<Object?> get props => [reason, duration, spentPlanck, isHost];
}

/// [back] is the Choosing state to return to on `RetryPressed`/`BackToStart`
/// — `null` only when the very first catalog load failed, before any
/// Choosing state had ever been reached.
class InterpreterFailure extends InterpreterState {
  final InterpreterErrorKind kind;
  final InterpreterChoosing? back;

  const InterpreterFailure({required this.kind, this.back});

  @override
  List<Object?> get props => [kind, back];
}
