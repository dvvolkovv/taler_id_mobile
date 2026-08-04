import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_exception.dart';
import '../utils/error_keys.dart';

class ApiErrorHandler {
  static ApiException handle(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ApiException(
        message: ErrorKeys.timeout,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const ApiException(
        message: ErrorKeys.noConnection,
      );
    }

    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    // Without this the reason for a failed call is invisible: the screen shows
    // whatever `message` held, the body is discarded, and there is no way to
    // tell an expired grant from a rejected scope. Cost a full session on a
    // 400 that read only "Internal server error" (2026-08-04).
    debugPrint(
      '[Api] ${e.requestOptions.method} ${e.requestOptions.uri} '
      '→ ${statusCode ?? e.type} ${responseData ?? e.message}',
    );

    String message = ErrorKeys.generalError;

    if (responseData is Map<String, dynamic>) {
      // Which field holds the reason depends on who raised the error, so take
      // the first one that says something. `message` is often the framework's
      // fixed "Internal server error" with the real reason left in `error`
      // (that shape is what /oauth/mobile/grant-info returns on a rejected
      // redirect_uri), while Nest's default filter does the reverse and puts
      // the bare HTTP status phrase in `error`. Preferring either field
      // outright buries the reason in one of the two cases.
      final candidates = [
        responseData['error_description'],
        responseData['message'],
        responseData['error'],
      ].whereType<String>().where((s) => s.isNotEmpty).toList();

      message = candidates.firstWhere(
        (s) => !_isGenericStatusPhrase(s),
        orElse: () => candidates.isEmpty ? message : candidates.first,
      );
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      data: responseData is Map<String, dynamic> ? responseData : null,
    );
  }

  /// Boilerplate an HTTP layer produces on its own, carrying no reason.
  static bool _isGenericStatusPhrase(String s) =>
      const {
        'internal server error',
        'bad request',
        'unauthorized',
        'forbidden',
        'not found',
        'conflict',
        'unprocessable entity',
        'too many requests',
        'service unavailable',
        'bad gateway',
      }.contains(s.trim().toLowerCase());
}
