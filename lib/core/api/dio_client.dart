import 'package:dio/dio.dart';
import '../utils/constants.dart';
import 'auth_interceptor.dart';
import 'api_error_handler.dart';

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  _RetryInterceptor(this.dio, {this.maxRetries = 2});

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
    final isNetworkError = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    // Don't retry logout — it's fire-and-forget; local cleanup runs regardless.
    final isLogout = err.requestOptions.path.contains('/auth/logout');

    if (isNetworkError && !isLogout && retryCount < maxRetries) {
      await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
      final opts = err.requestOptions;
      opts.extra['retryCount'] = retryCount + 1;
      try {
        final response = await dio.fetch(opts);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }
    return handler.next(err);
  }
}

class DioClient {
  late final Dio _dio;

  DioClient._internal(this._dio);

  static DioClient? _instance;

  static DioClient create({required AuthInterceptor authInterceptor}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_RetryInterceptor(dio));
    dio.interceptors.add(authInterceptor);
    dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      error: true,
    ));

    _instance = DioClient._internal(dio);
    return _instance!;
  }

  Dio get dio => _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return fromJson != null ? fromJson(response.data) : response.data as T;
    } on DioException catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return fromJson != null ? fromJson(response.data) : response.data as T;
    } on DioException catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return fromJson != null ? fromJson(response.data) : response.data as T;
    } on DioException catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return fromJson != null ? fromJson(response.data) : response.data as T;
    } on DioException catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<T> postForm<T>(
    String path, {
    required FormData formData,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return fromJson != null ? fromJson(response.data) : response.data as T;
    } on DioException catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
