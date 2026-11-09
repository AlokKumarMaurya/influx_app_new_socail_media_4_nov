import '../config/app_config.dart';

class UrlUtils {
  /// Ensures the provided URL is a full, absolute URL.
  /// If it starts with 'avatars/' or 'posts/', it prefixes it with the storage URL.
  /// If it's already a full URL, it replaces localhost with the configured host.
  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    // Get the base URL (remove /api if it exists)
    String baseUrl = AppConfig.baseUrl.replaceAll('/api', '');
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    final baseUri = Uri.tryParse(baseUrl);
    final targetHost = baseUri?.host;

    // If it's already a full URL (http or https)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      if (targetHost != null &&
          targetHost.isNotEmpty &&
          targetHost != 'localhost' &&
          targetHost != '127.0.0.1') {
        path = path
            .replaceAll('localhost', targetHost)
            .replaceAll('127.0.0.1', targetHost);
      }
      return path;
    }

    // If it starts with a slash, remove it for consistency
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;

    if (!cleanPath.startsWith('storage/') &&
        !cleanPath.startsWith('public/') &&
        !cleanPath.startsWith('assets/') &&
        !cleanPath.startsWith('uploads/') &&
        !cleanPath.startsWith('api/')) {
      cleanPath = 'storage/$cleanPath';
    }

    return '$baseUrl/$cleanPath';
  }

  /// Storage-relative path for chat attachments (e.g. chat-attachments/foo.webm).
  static String? mediaStoragePath(String? urlOrPath) {
    if (urlOrPath == null || urlOrPath.isEmpty) return null;

    final input = getFullUrl(urlOrPath);
    final streamUri = Uri.tryParse(input);
    final fromQuery = streamUri?.queryParameters['path'];
    if (fromQuery != null &&
        fromQuery.isNotEmpty &&
        !fromQuery.contains('media/stream')) {
      return fromQuery;
    }

    if (input.contains('/media/stream') && (fromQuery == null || fromQuery.isEmpty)) {
      return null;
    }

    String storagePath = input;
    if (storagePath.startsWith('http://') || storagePath.startsWith('https://')) {
      storagePath = Uri.parse(storagePath).path;
    }
    if (storagePath.startsWith('/')) {
      storagePath = storagePath.substring(1);
    }
    if (storagePath.startsWith('storage/')) {
      storagePath = storagePath.substring('storage/'.length);
    }
    if (storagePath.isEmpty || storagePath.contains('media/stream')) {
      return null;
    }
    return storagePath;
  }

  /// Stream URL with byte-range support (required for iOS video/voice playback).
  static String mediaStreamUrl(String? urlOrPath, {bool transcodeWebm = false}) {
    final storagePath = mediaStoragePath(urlOrPath);
    if (storagePath == null) return '';

    final apiBase = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl
        : '${AppConfig.baseUrl}/';

    final params = <String, String>{'path': storagePath};
    if (transcodeWebm || storagePath.toLowerCase().endsWith('.webm')) {
      params['transcode'] = '1';
    }

    return Uri.parse('${apiBase}media/stream').replace(queryParameters: params).toString();
  }
}
