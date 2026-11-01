import '../../../core/api/api_exception.dart';

/// One value per backend error code (spec table in the interpreter design),
/// plus [network] for a failed call that never reached the server and
/// [unknown] for anything else (non-API errors, or a code the client
/// doesn't recognise yet).
enum InterpreterErrorKind {
  interpreterDisabled,
  unsupportedLanguage,
  sameLanguage,
  voicePrintRequired,
  hostVoicePrintRequired,
  alreadyInSession,
  sameVoicePrint,
  ownCode,
  codeUsed,
  notWaiting,
  insufficientFunds,
  hostInsufficientFunds,
  featureDisabled,
  hostFeatureDisabled,
  codeNotFound,
  sessionNotFound,
  codeExpired,
  tooManyAttempts,
  interpreterUnavailable,
  network,
  unknown,
}

const Map<String, InterpreterErrorKind> _kindByCode = {
  'interpreter_disabled': InterpreterErrorKind.interpreterDisabled,
  'unsupported_language': InterpreterErrorKind.unsupportedLanguage,
  'same_language': InterpreterErrorKind.sameLanguage,
  'voice_print_required': InterpreterErrorKind.voicePrintRequired,
  'host_voice_print_required': InterpreterErrorKind.hostVoicePrintRequired,
  'already_in_session': InterpreterErrorKind.alreadyInSession,
  'same_voice_print': InterpreterErrorKind.sameVoicePrint,
  'own_code': InterpreterErrorKind.ownCode,
  'code_used': InterpreterErrorKind.codeUsed,
  'not_waiting': InterpreterErrorKind.notWaiting,
  'insufficient_funds': InterpreterErrorKind.insufficientFunds,
  'host_insufficient_funds': InterpreterErrorKind.hostInsufficientFunds,
  'feature_disabled': InterpreterErrorKind.featureDisabled,
  'host_feature_disabled': InterpreterErrorKind.hostFeatureDisabled,
  'code_not_found': InterpreterErrorKind.codeNotFound,
  'session_not_found': InterpreterErrorKind.sessionNotFound,
  'code_expired': InterpreterErrorKind.codeExpired,
  'too_many_attempts': InterpreterErrorKind.tooManyAttempts,
  'interpreter_unavailable': InterpreterErrorKind.interpreterUnavailable,
};

/// Thrown by every [InterpreterRepository] method. Screens switch on [kind]
/// to show the per-code text the spec calls for, instead of a generic error.
class InterpreterException implements Exception {
  final InterpreterErrorKind kind;
  final int? statusCode;

  const InterpreterException(this.kind, {this.statusCode});

  /// [error] is normally the [ApiException] a datasource call raised (or, for
  /// the `join` call, one built by hand from [ApiErrorHandler.handle] since
  /// that call bypasses `DioClient`'s own try/catch to set a longer timeout).
  /// A `statusCode == null` means the request never got a response — no
  /// point reading a body that isn't there, so that maps straight to
  /// [InterpreterErrorKind.network]. Anything that isn't an [ApiException] at
  /// all (a parsing bug, a plain [Exception]) maps to [unknown] rather than
  /// pretending to know its status code.
  factory InterpreterException.from(Object error) {
    // Already mapped (the repository throws these): keep its kind.
    if (error is InterpreterException) return error;
    if (error is ApiException) {
      if (error.statusCode == null) {
        return const InterpreterException(InterpreterErrorKind.network);
      }
      final code = _codeOf(error.data);
      final kind = code == null
          ? InterpreterErrorKind.unknown
          : _kindByCode[code] ?? InterpreterErrorKind.unknown;
      return InterpreterException(kind, statusCode: error.statusCode);
    }
    return const InterpreterException(InterpreterErrorKind.unknown);
  }

  /// The backend's error body is `{statusCode, message: '<code>' | ['<code>']}`
  /// — `message` is a bare string on most errors but a validation pipe can
  /// turn it into a list; either shape names the code in the same place.
  static String? _codeOf(Map<String, dynamic>? data) {
    final raw = data?['message'];
    if (raw is String) return raw;
    if (raw is List && raw.isNotEmpty && raw.first is String) {
      return raw.first as String;
    }
    return null;
  }

  @override
  String toString() =>
      'InterpreterException(${kind.name}, statusCode: $statusCode)';
}
