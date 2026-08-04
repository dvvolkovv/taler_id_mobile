// Cover for which field of a backend error actually reaches the user.
//
// A 400 from /oauth/mobile/grant-info arrives as
//   {"statusCode":400,"message":"Internal server error","error":"redirect_uri_mismatch"}
// — the reason sits in `error` while `message` carries a fixed phrase. Reading
// `message` turned every such failure into "Internal server error" and cost two
// sessions of guessing on the Linkeon login (2026-08-03/04).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/api/api_error_handler.dart';

void main() {
  ApiExceptionMessage handle(int status, Map<String, dynamic> body) {
    final options = RequestOptions(path: '/oauth/mobile/grant-info');
    final e = DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: status,
        data: body,
      ),
      type: DioExceptionType.badResponse,
    );
    return ApiExceptionMessage(ApiErrorHandler.handle(e).message);
  }

  test('surfaces `error` when `message` is the generic placeholder', () {
    final r = handle(400, {
      'statusCode': 400,
      'message': 'Internal server error',
      'error': 'redirect_uri_mismatch',
    });

    expect(r.value, 'redirect_uri_mismatch');
  });

  test('keeps a specific `message` over a generic `error`', () {
    // Nest's default filter puts the HTTP status phrase in `error`; the real
    // reason is in `message` here, and preferring `error` would replace
    // "Invalid or expired token" with a useless "Unauthorized".
    final r = handle(401, {
      'statusCode': 401,
      'message': 'Invalid or expired token',
      'error': 'Unauthorized',
    });

    expect(r.value, 'Invalid or expired token');
  });

  test('prefers error_description over both', () {
    final r = handle(400, {
      'message': 'Internal server error',
      'error': 'invalid_grant',
      'error_description': 'The authorization code has expired',
    });

    expect(r.value, 'The authorization code has expired');
  });

  test('falls back to the placeholder when nothing else is specific', () {
    final r = handle(500, {
      'statusCode': 500,
      'message': 'Internal server error',
      'error': 'Internal Server Error',
    });

    expect(r.value, 'Internal server error');
  });
}

/// Thin wrapper so a failing expectation prints the message, not the exception.
class ApiExceptionMessage {
  const ApiExceptionMessage(this.value);
  final String value;
}
