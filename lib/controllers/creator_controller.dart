import 'package:get/get.dart';
import '../data/services/creator_service.dart';

class CreatorController extends GetxController {
  final CreatorService _service = CreatorService();

  // Stats
  final totalPosts = 0.obs;
  final totalViews = 0.obs;
  final totalReach = 0.obs;
  final totalInteractions = 0.obs;

  // Chart
  final chartLabels = <String>[].obs;
  final chartViews = <double>[].obs;
  final chartReach = <double>[].obs;

  // Top Posts
  final topPosts = <Map<String, dynamic>>[].obs;

  // Loading
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      final data = await _service.getDashboard();

      if (data['success'] == true) {
        final stats = data['stats'] as Map<String, dynamic>;
        totalPosts.value = (stats['total_posts'] as num?)?.toInt() ?? 0;
        totalViews.value = (stats['total_views'] as num?)?.toInt() ?? 0;
        totalReach.value = (stats['total_reach'] as num?)?.toInt() ?? 0;
        totalInteractions.value = (stats['total_interactions'] as num?)?.toInt() ?? 0;

        final chart = data['chart'] as Map<String, dynamic>;
        chartLabels.value = List<String>.from(chart['labels'] ?? []);
        chartViews.value = (chart['views'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
        chartReach.value = (chart['reach'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];

        topPosts.value = List<Map<String, dynamic>>.from(
          (data['top_posts'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
        );
      }
    } catch (e) {
      Get.log('Creator dashboard error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await loadDashboard();
  }
}
