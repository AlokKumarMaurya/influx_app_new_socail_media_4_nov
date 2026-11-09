import 'package:get/get.dart';
import '../data/models/campaign_model.dart';
import '../data/models/post_model.dart';
import '../data/models/story_model.dart';
import '../data/models/creator_model.dart';
import '../data/models/blog_model.dart';
import '../data/models/event_model.dart';
import '../data/services/discover_service.dart';
import 'package:get_storage/get_storage.dart';
import 'settings_controller.dart';

class DiscoverFeedController extends GetxController {
  final DiscoverService _discoverService = DiscoverService();

  final activeNiche = 'For You'.obs;
  final isLoading = true.obs;

  // Sections data
  final stats = <String, dynamic>{}.obs;
  final stories = <StoryGroup>[].obs;
  final trendingCreators = <CreatorModel>[].obs;
  final openCampaigns = <CampaignModel>[].obs;
  final creatorPosts = <PostModel>[].obs;
  final creatorPitches = <CampaignModel>[].obs;
  final blogs = <BlogModel>[].obs;
  final events = <EventModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDiscoverData();
  }

  Future<void> loadDiscoverData() async {
    isLoading.value = true;
    try {
      final data = await _discoverService.getDiscover(
        activeNiche.value == 'For You' ? null : activeNiche.value.toLowerCase(),
      );

      stats.value = data['stats'] ?? {};
      stories.value = data['stories'] ?? [];
      trendingCreators.value = data['trending_creators'] ?? [];
      openCampaigns.value = data['open_campaigns'] ?? [];
      creatorPosts.value = data['creator_posts'] ?? [];
      creatorPitches.value = data['creator_pitches'] ?? [];
      blogs.value = data['blogs'] ?? [];
      events.value = data['events'] ?? [];

      final symbol = data['currency_symbol'] ?? '\$';
      final currencyCode = data['currency'] ?? 'USD';
      if (Get.isRegistered<SettingsController>()) {
        final settingsController = Get.find<SettingsController>();
        settingsController.currencySymbol.value = symbol;
        settingsController.currency.value = currencyCode;
      }
      final GetStorage storage = GetStorage();
      storage.write('currency_symbol', symbol);
      storage.write('currency', currencyCode);
    } catch (e) {
      Get.log('Error loading discover feed data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changeNiche(String niche) {
    if (activeNiche.value == niche) return;
    activeNiche.value = niche;
    loadDiscoverData();
  }

  Future<void> refreshData() async {
    await loadDiscoverData();
  }
}
