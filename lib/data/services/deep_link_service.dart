import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../config/app_config.dart';
import '../../pages/feed/single_post_page.dart';
import '../../pages/user/profile_page.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  void init() {
    _initInitialLink();
    _initLinkSubscription();
  }

  Future<void> _initInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        // Small delay to ensure widget tree is mounted
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(initialUri);
        });
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }
  }

  void _initLinkSubscription() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Error listening to deep links stream: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received Deep Link: $uri');

    // Extract path segments (works for both http/https web URLs and custom schemes e.g. influx://posts/90)
    final segments = uri.pathSegments;
    
    // Handle custom scheme format e.g., influx://posts/90 where host is 'posts' and path is '/90'
    String resource = '';
    String? idStr;

    if (uri.scheme == AppConfig.deepLinkScheme) {
      if (uri.host.isNotEmpty) {
        resource = uri.host.toLowerCase();
        if (segments.isNotEmpty) {
          idStr = segments[0];
        }
      }
    }

    if (resource.isEmpty && segments.isNotEmpty) {
      resource = segments[0].toLowerCase();
      if (segments.length >= 2) {
        idStr = segments[1];
      }
    }

    if (resource.isEmpty) return;

    // 1. Posts (/posts/{id} or /post/{id})
    if (resource == 'posts' || resource == 'post') {
      if (idStr != null) {
        final postId = int.tryParse(idStr);
        if (postId != null) {
          Get.to(() => SinglePostPage(postId: postId));
          return;
        }
      }
    }

    // 2. User Profile (/profile/{id} or /user/{id} or /u/{id})
    if (resource == 'profile' || resource == 'user' || resource == 'u') {
      if (idStr != null) {
        final userId = int.tryParse(idStr);
        if (userId != null) {
          Get.to(() => ProfilePage(userId: userId));
          return;
        }
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
