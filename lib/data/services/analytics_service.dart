import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../providers/api_client.dart';

class AnalyticsService {
  final Dio _dio = ApiClient().dio;

  // Local cache to prevent duplicate hits in the same session/short time
  static final Set<String> _recordedPostViews = {};
  static final Set<String> _recordedVideoViews = {};
  static final Set<String> _recordedAdViews = {};

  /// Record a view for a specific post.
  Future<void> recordPostView(int postId) async {
    final key = 'post_$postId';
    if (_recordedPostViews.contains(key)) return;

    try {
      await _dio.post('/analytics/post-view', data: {'post_id': postId});
      _recordedPostViews.add(key);
    } catch (e) {
      // Quietly fail for analytics
      debugPrint('Error recording post view: $e');
    }
  }

  /// Record a view for a video item.
  Future<void> recordVideoView(int mediaId) async {
    final key = 'video_$mediaId';
    if (_recordedVideoViews.contains(key)) return;

    try {
      await _dio.post('/analytics/video-view', data: {'media_id': mediaId});
      _recordedVideoViews.add(key);
    } catch (e) {
      debugPrint('Error recording video view: $e');
    }
  }

  /// Record an ad impression.
  Future<void> recordAdView(int adId) async {
    final key = 'ad_$adId';
    if (_recordedAdViews.contains(key)) return;

    try {
      await _dio.post('/analytics/ad-view', data: {'ad_id': adId});
      _recordedAdViews.add(key);
    } catch (e) {
      debugPrint('Error recording ad impression: $e');
    }
  }

  /// Record an ad click.
  Future<void> recordAdClick(int adId) async {
    try {
      await _dio.post('/analytics/ad-click', data: {'ad_id': adId});
    } catch (e) {
      debugPrint('Error recording ad click: $e');
    }
  }
}
