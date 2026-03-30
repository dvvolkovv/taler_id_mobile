import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/api/api_error_handler.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';

DioException _makeDioError({
  required DioExceptionType type,
  int? statusCode,
  dynamic data,
}) {
  return DioException(
    type: type,
    requestOptions: RequestOptions(path: '/test'),
    response: statusCode != null
        ? Response(
            statusCode: statusCode,
            data: data,
            requestOptions: RequestOptions(path: '/test'),
          )
        : null,
  );
}

void main() {
  // ── Timeout errors ────────────────────────────────────────────────────

  group('timeout errors', () {
    test('connectionTimeout returns timeout message', () {
      final err = _makeDioError(type: DioExceptionType.connectionTimeout);
      final result = ApiErrorHandler.handle(err);

      expect(result, isA<ApiException>());
      expect(result.message, contains('время ожидания'));
      expect(result.statusCode, isNull);
    });

    test('receiveTimeout returns timeout message', () {
      final err = _makeDioError(type: DioExceptionType.receiveTimeout);
      final result = ApiErrorHandler.handle(err);

      expect(result.message, contains('время ожидания'));
    });

    test('sendTimeout returns timeout message', () {
      final err = _makeDioError(type: DioExceptionType.sendTimeout);
      final result = ApiErrorHandler.handle(err);

      expect(result.message, contains('время ожидания'));
    });
  });

  // ── Connection error ──────────────────────────────────────────────────

  group('connection error', () {
    test('returns offline message', () {
      final err = _makeDioError(type: DioExceptionType.connectionError);
      final result = ApiErrorHandler.handle(err);

      expect(result.message, contains('подключения к интернету'));
    });
  });

  // ── Server response errors ────────────────────────────────────────────

  group('server response errors', () {
    test('extracts message from response body', () {
      final err = _makeDioError(
        type: DioExceptionType.badResponse,
        statusCode: 400,
        data: {'message': 'Validation failed'},
      );
      final result = ApiErrorHandler.handle(err);

      expect(result.statusCode, 400);
      expect(result.message, 'Validation failed');
      expect(result.data, isNotNull);
    });

    test('extracts error field when message is missing', () {
      final err = _makeDioError(
        type: DioExceptionType.badResponse,
        statusCode: 500,
        data: {'error': 'Internal server error'},
      );
      final result = ApiErrorHandler.handle(err);

      expect(result.statusCode, 500);
      expect(result.message, 'Internal server error');
    });

    test('uses default message when response has no message/error', () {
      final err = _makeDioError(
        type: DioExceptionType.badResponse,
        statusCode: 422,
        data: {'details': 'some details'},
      );
      final result = ApiErrorHandler.handle(err);

      expect(result.statusCode, 422);
      expect(result.message, contains('Произошла ошибка'));
    });

    test('handles non-map response data gracefully', () {
      final err = _makeDioError(
        type: DioExceptionType.badResponse,
        statusCode: 503,
        data: 'Service unavailable',
      );
      final result = ApiErrorHandler.handle(err);

      expect(result.statusCode, 503);
      expect(result.message, contains('Произошла ошибка'));
      expect(result.data, isNull);
    });

    test('handles null response data', () {
      final err = _makeDioError(
        type: DioExceptionType.badResponse,
        statusCode: 401,
        data: null,
      );
      final result = ApiErrorHandler.handle(err);

      expect(result.statusCode, 401);
      expect(result.isUnauthorized, isTrue);
    });
  });

  // ── ApiException helpers ──────────────────────────────────────────────

  group('ApiException', () {
    test('isUnauthorized returns true for 401', () {
      const ex = ApiException(statusCode: 401, message: 'Unauthorized');
      expect(ex.isUnauthorized, isTrue);
      expect(ex.isNotFound, isFalse);
      expect(ex.isServerError, isFalse);
    });

    test('isNotFound returns true for 404', () {
      const ex = ApiException(statusCode: 404, message: 'Not found');
      expect(ex.isNotFound, isTrue);
    });

    test('isServerError returns true for 5xx', () {
      const ex500 = ApiException(statusCode: 500, message: 'ISE');
      const ex503 = ApiException(statusCode: 503, message: 'Unavailable');
      expect(ex500.isServerError, isTrue);
      expect(ex503.isServerError, isTrue);
    });

    test('toString includes statusCode and message', () {
      const ex = ApiException(statusCode: 403, message: 'Forbidden');
      expect(ex.toString(), 'ApiException(403): Forbidden');
    });

    test('null statusCode helpers return false', () {
      const ex = ApiException(message: 'Unknown');
      expect(ex.isUnauthorized, isFalse);
      expect(ex.isNotFound, isFalse);
      expect(ex.isServerError, isFalse);
    });
  });
}
