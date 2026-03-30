import 'package:dio/dio.dart';
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

    String message = ErrorKeys.generalError;

    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] as String? ??
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
