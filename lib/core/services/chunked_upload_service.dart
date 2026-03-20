import 'dart:io';
import 'package:dio/dio.dart';
import '../api/dio_client.dart';
import '../di/service_locator.dart';

class ChunkedUploadResult {
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String fileType;
  final String s3Key;
  final String? thumbnailSmallUrl;
  final String? thumbnailMediumUrl;
  final String? thumbnailLargeUrl;
  final String? fileRecordId;

  ChunkedUploadResult({
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.s3Key,
    this.thumbnailSmallUrl,
    this.thumbnailMediumUrl,
    this.thumbnailLargeUrl,
    this.fileRecordId,
  });
}

class ChunkedUploadService {
  static const int chunkSize = 5 * 1024 * 1024; // 5MB (S3 minimum)
  static const int maxRetries = 3;

  static const _mimeMap = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'avi': 'video/x-msvideo',
    'mp3': 'audio/mpeg',
    'aac': 'audio/aac',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'm4a': 'audio/mp4',
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };

  /// Detect MIME type from file name extension.
  static String detectMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return _mimeMap[ext] ?? 'application/octet-stream';
  }

  /// Upload a file, using chunked upload for files >= 5MB, single POST otherwise.
  /// Deduplication is handled server-side (pixel-hash for images).
  /// [onProgress] receives 0.0 to 1.0
  static Future<ChunkedUploadResult> upload({
    required String filePath,
    required String fileName,
    CancelToken? cancelToken,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(filePath);
    final fileSize = await file.length();

    // Small files: use existing single POST
    if (fileSize < chunkSize) {
      return _singleUpload(filePath, fileName,
          cancelToken: cancelToken, onProgress: onProgress);
    }

    // Large files: chunked upload
    return _chunkedUpload(filePath, fileName, fileSize,
        cancelToken: cancelToken, onProgress: onProgress);
  }

  static Future<ChunkedUploadResult> _singleUpload(
    String filePath,
    String fileName, {
    CancelToken? cancelToken,
    void Function(double)? onProgress,
  }) async {
    final client = sl<DioClient>();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final res = await client.dio.post<Map<String, dynamic>>(
      '/messenger/files',
      data: formData,
      cancelToken: cancelToken,
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );
    final data = res.data!;
    return ChunkedUploadResult(
      fileUrl: data['fileUrl'] as String,
      fileName: data['fileName'] as String,
      fileSize: data['fileSize'] as int,
      fileType: data['fileType'] as String? ?? 'document',
      s3Key: data['s3Key'] as String? ?? '',
      thumbnailSmallUrl: data['thumbnailSmallUrl'] as String?,
      thumbnailMediumUrl: data['thumbnailMediumUrl'] as String?,
      thumbnailLargeUrl: data['thumbnailLargeUrl'] as String?,
      fileRecordId: data['fileRecordId'] as String?,
    );
  }

  static Future<ChunkedUploadResult> _chunkedUpload(
    String filePath,
    String fileName,
    int fileSize, {
    CancelToken? cancelToken,
    void Function(double)? onProgress,
  }) async {
    final client = sl<DioClient>();
    final file = File(filePath);

    // Determine MIME type
    final mimeType = detectMimeType(fileName);

    // 1. Init
    final initRes = await client.dio.post<Map<String, dynamic>>(
      '/messenger/files/init',
      data: {
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': mimeType,
      },
      cancelToken: cancelToken,
    );
    final uploadId = initRes.data!['uploadId'] as String;
    final totalParts = initRes.data!['totalParts'] as int;

    // 2. Upload chunks
    final raf = await file.open();
    try {
      for (int i = 1; i <= totalParts; i++) {
        if (cancelToken?.isCancelled == true) {
          // Abort on server
          try {
            await client.dio.delete('/messenger/files/$uploadId');
          } catch (_) {}
          throw DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.cancel,
          );
        }

        final offset = (i - 1) * chunkSize;
        final length = (i == totalParts) ? fileSize - offset : chunkSize;

        await raf.setPosition(offset);
        final chunkData = await raf.read(length);

        // Retry logic
        for (int attempt = 0; attempt < maxRetries; attempt++) {
          try {
            final formData = FormData.fromMap({
              'uploadId': uploadId,
              'partNumber': i.toString(),
              'chunk':
                  MultipartFile.fromBytes(chunkData, filename: 'chunk_$i'),
            });
            await client.dio.post(
              '/messenger/files/chunk',
              data: formData,
              cancelToken: cancelToken,
            );
            break; // success
          } catch (e) {
            if (attempt == maxRetries - 1) rethrow;
            if (cancelToken?.isCancelled == true) rethrow;
            await Future.delayed(
                Duration(seconds: (attempt + 1) * 2)); // exponential backoff
          }
        }

        // Progress: chunk completion
        onProgress?.call(i / totalParts);
      }
    } finally {
      await raf.close();
    }

    // 3. Complete
    final completeRes = await client.dio.post<Map<String, dynamic>>(
      '/messenger/files/complete',
      data: {'uploadId': uploadId},
      cancelToken: cancelToken,
    );
    final data = completeRes.data!;
    return ChunkedUploadResult(
      fileUrl: data['fileUrl'] as String,
      fileName: data['fileName'] as String,
      fileSize: data['fileSize'] as int,
      fileType: data['fileType'] as String? ?? 'document',
      s3Key: data['s3Key'] as String? ?? '',
      thumbnailSmallUrl: data['thumbnailSmallUrl'] as String?,
      thumbnailMediumUrl: data['thumbnailMediumUrl'] as String?,
      thumbnailLargeUrl: data['thumbnailLargeUrl'] as String?,
      fileRecordId: data['fileRecordId'] as String?,
    );
  }
}
