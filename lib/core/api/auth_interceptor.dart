import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final SecureStorageService storage;

  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshQueue = [];

  AuthInterceptor({required this.dio, required this.storage});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true ||
        options.path.contains('/auth/forgot-password')) {
      handler.next(options);
      return;
    }
    final token = await storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Don't retry refresh endpoint itself
    if (err.requestOptions.path.contains('/auth/refresh') ||
        err.requestOptions.path.contains('/auth/login') ||
        err.requestOptions.path.contains('/auth/register') ||
        err.requestOptions.path.contains('/auth/forgot-password')) {
      handler.next(err);
      return;
    }

    final newToken = await _refreshAccessToken();
    if (newToken == null) {
      handler.next(err);
      return;
    }

    // Retry original request with new token
    try {
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newToken';
      final response = await dio.fetch(opts);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    }
  }

  Future<String?> _refreshAccessToken() async {
    if (_isRefreshing) {
      // Queue this request
      final completer = Completer<String?>();
      _refreshQueue.add(completer);
      return completer.future;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null) return null;

      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: <String, dynamic>{}, // Don't send old expired token
          extra: {'skipAuth': true},
        ),
      );

      final newAccessToken = response.data['accessToken'] as String;
      final newRefreshToken = response.data['refreshToken'] as String?;

      await storage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken ?? refreshToken,
      );

      // Save user ID from refreshed token
      try {
        final parts = newAccessToken.split('.');
        if (parts.length == 3) {
          final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          final map = jsonDecode(payload) as Map<String, dynamic>;
          final sub = map['sub'] as String?;
          if (sub != null) await storage.saveUserId(sub);
        }
      } catch (_) {}

      // Resolve all queued requests
      for (final completer in _refreshQueue) {
        completer.complete(newAccessToken);
      }
      _refreshQueue.clear();

      return newAccessToken;
    } catch (e) {
      // Refresh failed — clear tokens and reject queue
      await storage.clearTokens();
      for (final completer in _refreshQueue) {
        completer.complete(null);
      }
      _refreshQueue.clear();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }
}
