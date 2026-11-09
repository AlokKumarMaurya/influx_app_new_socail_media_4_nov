import 'dart:io';
import 'package:dio/dio.dart';
import '../providers/api_client.dart';
import '../models/campaign_model.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../models/blog_model.dart';
import '../models/event_model.dart';
import '../models/creator_model.dart';

class DiscoverService {
  final Dio _dio = ApiClient().dio;

  /// Fetch all sections on the Discover feed.
  Future<Map<String, dynamic>> getDiscover(String? niche) async {
    try {
      final queryParams = <String, dynamic>{};
      if (niche != null && niche != 'For You') {
        queryParams['niche'] = niche;
      }

      final response = await _dio.get('/discover', queryParameters: queryParams);
      final rawData = response.data['data'] as Map<String, dynamic>;

      // Parse Stats
      final stats = Map<String, dynamic>.from(rawData['stats'] ?? {});

      // Parse Stories
      final rawStories = rawData['stories'] as List? ?? [];
      final List<StoryGroup> stories = rawStories.map((group) {
        final user = UserModel.fromJson(group['user']);
        final storiesList = (group['stories'] as List? ?? [])
            .map((s) => StoryModel.fromJson(s))
            .toList();
        return StoryGroup(
          user: user,
          stories: storiesList,
          hasUnseenStories: group['has_unseen'] ?? true,
        );
      }).toList();

      // Parse Trending Creators
      final rawCreators = rawData['trending_creators'] as List? ?? [];
      final List<CreatorModel> trendingCreators = rawCreators.map((c) {
        // Build simulated CreatorModel from simpler payload if needed
        return CreatorModel.fromJson(c);
      }).toList();

      // Parse Open Campaigns
      final rawOpenCampaigns = rawData['open_campaigns'] as List? ?? [];
      final List<CampaignModel> openCampaigns = rawOpenCampaigns
          .map((c) => CampaignModel.fromJson(c))
          .toList();

      // Parse Creator Posts
      final rawCreatorPosts = rawData['creator_posts'] as List? ?? [];
      final List<PostModel> creatorPosts = rawCreatorPosts
          .map((p) => PostModel.fromJson(p))
          .toList();

      // Parse Creator Pitches
      final rawCreatorPitches = rawData['creator_pitches'] as List? ?? [];
      final List<CampaignModel> creatorPitches = rawCreatorPitches
          .map((c) => CampaignModel.fromJson(c))
          .toList();

      // Parse Blogs
      final rawBlogs = rawData['blogs'] as List? ?? [];
      final List<BlogModel> blogs = rawBlogs
          .map((b) => BlogModel.fromJson(b))
          .toList();

      // Parse Events
      final rawEvents = rawData['events'] as List? ?? [];
      final List<EventModel> events = rawEvents
          .map((e) => EventModel.fromJson(e))
          .toList();

      return {
        'stats': stats,
        'stories': stories,
        'trending_creators': trendingCreators,
        'open_campaigns': openCampaigns,
        'creator_posts': creatorPosts,
        'creator_pitches': creatorPitches,
        'blogs': blogs,
        'events': events,
        'currency_symbol': rawData['currency_symbol'] ?? '\$',
        'currency': rawData['currency'] ?? 'USD',
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get campaigns list (paginated).
  Future<Map<String, dynamic>> getCampaigns({
    String? niche,
    String? search,
    String? type,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (niche != null && niche != 'All') {
        queryParams['niche'] = niche;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (type != null && type != 'All') {
        queryParams['type'] = type;
      }

      final response = await _dio.get('/campaigns', queryParameters: queryParams);
      final rawData = response.data['data'] as Map<String, dynamic>;

      final campaignsList = (rawData['data'] as List)
          .map((c) => CampaignModel.fromJson(c))
          .toList();

      return {
        'campaigns': campaignsList,
        'currentPage': rawData['current_page'],
        'lastPage': rawData['last_page'],
        'nextPageUrl': rawData['next_page_url'],
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Show details of a single campaign.
  Future<CampaignModel> getCampaignDetails(int id) async {
    try {
      final response = await _dio.get('/campaigns/$id');
      return CampaignModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// List owner's campaigns.
  Future<Map<String, dynamic>> getMyCampaigns({int page = 1}) async {
    try {
      final response = await _dio.get('/campaigns/my', queryParameters: {'page': page});
      final rawData = response.data['data'] as Map<String, dynamic>;

      final campaignsList = (rawData['data'] as List)
          .map((c) => CampaignModel.fromJson(c))
          .toList();

      return {
        'campaigns': campaignsList,
        'currentPage': rawData['current_page'],
        'lastPage': rawData['last_page'],
        'nextPageUrl': rawData['next_page_url'],
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Create a campaign.
  Future<CampaignModel> createCampaign({
    required String title,
    required String type,
    required String mediaType,
    required String status,
    String? description,
    String? niche,
    double? budgetFrom,
    double? budgetTo,
    List<String>? platforms,
    List<File>? mediaFiles,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'title': title,
        'type': type,
        'media_type': mediaType,
        'status': status,
        'description': description,
        'niche': niche,
        'budget_from': budgetFrom,
        'budget_to': budgetTo,
      }..removeWhere((key, value) => value == null);

      final formData = FormData.fromMap(data);

      if (platforms != null && platforms.isNotEmpty) {
        for (final platform in platforms) {
          formData.fields.add(MapEntry('platforms[]', platform));
        }
      }

      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (final file in mediaFiles) {
          formData.files.add(MapEntry(
            'media[]',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ));
        }
      }

      final response = await _dio.post('/campaigns', data: formData);
      return CampaignModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Update a campaign.
  Future<CampaignModel> updateCampaign(
    int id, {
    required String title,
    required String type,
    required String mediaType,
    required String status,
    String? description,
    String? niche,
    double? budgetFrom,
    double? budgetTo,
    List<String>? platforms,
    List<File>? mediaFiles,
  }) async {
    try {
      final Map<String, dynamic> data = {
        '_method': 'POST', // standard override for uploading files on update in Laravel
        'title': title,
        'type': type,
        'media_type': mediaType,
        'status': status,
        'description': description,
        'niche': niche,
        'budget_from': budgetFrom,
        'budget_to': budgetTo,
      }..removeWhere((key, value) => value == null);

      // Since forms are submitted, clear old platforms and re-add
      if (platforms != null) {
        if (platforms.isEmpty) {
          data['platforms'] = [];
        } else {
          for (int i = 0; i < platforms.length; i++) {
            data['platforms[$i]'] = platforms[i];
          }
        }
      }

      final formData = FormData.fromMap(data);

      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (final file in mediaFiles) {
          formData.files.add(MapEntry(
            'media[]',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ));
        }
      }

      // POST with _method = POST or _method in payload is safer when uploading files
      final response = await _dio.post('/campaigns/$id', data: formData);
      return CampaignModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a campaign.
  Future<void> deleteCampaign(int id) async {
    try {
      await _dio.delete('/campaigns/$id');
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a campaign media file.
  Future<void> deleteCampaignMedia(int campaignId, int mediaId) async {
    try {
      await _dio.delete('/campaigns/$campaignId/media/$mediaId');
    } catch (e) {
      rethrow;
    }
  }
}
