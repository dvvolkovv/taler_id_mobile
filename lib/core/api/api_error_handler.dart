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
      // error_description first: our backend puts the actual reason there and
      // leaves `message` as the framework's generic "Internal server error",
      // so preferring `message` hid every real error behind that phrase.
      message = responseData['error_description'] as String? ??
          responseData['message'] as String? ??
          responseData['error'] as String? ??
          message;
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      data: responseData is Map<String, dynamic> ? responseData : null,
    );
  }
}
