import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_error.dart';

ApiException _apiError(int statusCode, String code) => ApiException(
      statusCode: statusCode,
      message: code,
      data: {'statusCode': statusCode, 'message': code},
    );

void main() {
  group('InterpreterException.from — every backend code', () {
    const codes = {
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

    codes.forEach((code, expectedKind) {
      test('maps "$code"', () {
        final exception = InterpreterException.from(_apiError(409, code));
        expect(exception.kind, expectedKind);
        expect(exception.statusCode, 409);
      });
    });
  });

  test('message as the first string of a list maps the same way', () {
    final exception = InterpreterException.from(ApiException(
      statusCode: 400,
      message: 'ignored',
      data: {
        'message': ['same_language', 'extra context']
      },
    ));
    expect(exception.kind, InterpreterErrorKind.sameLanguage);
  });

  test('a code the client does not recognise maps to unknown', () {
    final exception =
        InterpreterException.from(_apiError(400, 'brand_new_code'));
    expect(exception.kind, InterpreterErrorKind.unknown);
    expect(exception.statusCode, 400);
  });

  test('missing data map maps to unknown', () {
    final exception = InterpreterException.from(
      const ApiException(statusCode: 500, message: 'boom'),
    );
    expect(exception.kind, InterpreterErrorKind.unknown);
    expect(exception.statusCode, 500);
  });

  test('null statusCode (no response reached the server) maps to network', () {
    final exception = InterpreterException.from(
      const ApiException(message: 'timeout'),
    );
    expect(exception.kind, InterpreterErrorKind.network);
    expect(exception.statusCode, isNull);
  });

  test('an InterpreterException passes through with its kind', () {
    const original =
        InterpreterException(InterpreterErrorKind.codeUsed, statusCode: 409);
    expect(InterpreterException.from(original), same(original));
  });

  test('a non-ApiException error maps to unknown', () {
    final exception = InterpreterException.from(Exception('boom'));
    expect(exception.kind, InterpreterErrorKind.unknown);
    expect(exception.statusCode, isNull);
  });
}
