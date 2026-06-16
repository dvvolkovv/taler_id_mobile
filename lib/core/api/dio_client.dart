import 'package:dio/dio.dart';
import '../utils/constants.dart';
import 'auth_interceptor.dart';
import 'api_error_handler.dart';
import 'billing_paywall_interceptor.dart';
import 'endpoint_service.dart';

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final EndpointService? endpoint;

  _RetryInterceptor(this.dio, {this.maxRetries = 2, this.endpoint});

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

    // Transient retries on the current endpoint are exhausted. If this is a CIS
    // build with RU edges, fail over to the next endpoint and retry there. This
    // is what moves a DPI-blocked client onto ru/ru2.talerid.io.
    final ep = endpoint;
    final failoverCount = err.requestOptions.extra['failoverCount'] as int? ?? 0;
    if (isNetworkError &&
        !isLogout &&
        ep != null &&
        ep.hasFallback &&
        failoverCount < ep.candidates.length - 1) {
      final switched = await ep.reportFailureAndFallback();
      if (switched) {
        final opts = err.requestOptions;
        opts.baseUrl = ep.baseUrl; // retarget this request at the new edge
        opts.extra['retryCount'] = 0; // fresh transient retries on the new base
        opts.extra['failoverCount'] = failoverCount + 1;
        try {
          final response = await dio.fetch(opts);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      }
    }
    return handler.next(err);
  }
}

class DioClient {
  late final Dio _dio;

  DioClient._internal(this._dio);

  static DioClient? _instance;

  static DioClient create({
    required AuthInterceptor authInterceptor,
    EndpointService? endpoint,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: endpoint?.baseUrl ?? ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Keep this client's baseUrl in lock-step with the resolved endpoint so all
    // FUTURE requests use the edge once we've failed over (the interceptor only
    // retargets the in-flight request).
    endpoint?.activeUrl.addListener(() {
      dio.options.baseUrl = endpoint.baseUrl;
    });

    // Order rationale: retry first (transient errors get a second chance
    // before anything else reacts), auth next (token refresh + retry on 401),
    // then paywall (we react to 402 which auth/retry can't recover from),
    // finally log (observability after everyone has had their say).
    dio.interceptors.add(_RetryInterceptor(dio, endpoint: endpoint));
    dio.interceptors.add(authInterceptor);
    dio.interceptors.add(BillingPaywallInterceptor());
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

  Future<T> deleteWithResponse<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(path, data: data);
      return fromJson != null ? fromJson(response.data) : response.data as T;
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

  Future<T> uploadFile<T>(
    String path, {
    required FormData formData,
    T Function(dynamic)? fromJson,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );
      return fromJson != null ? fromJson(response.data) : response.data as T;
    } on DioException catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
