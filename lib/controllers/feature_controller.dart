import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../data/providers/api_client.dart';

class FeatureController extends GetxController {
  static FeatureController get to => Get.find<FeatureController>();

  final ApiClient _apiClient = ApiClient();
  final RxBool isLoading = true.obs;
  final RxMap<String, bool> features = <String, bool>{}.obs;
  final RxMap<String, dynamic> rawFeatures = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFeatures();
  }

  Future<void> fetchFeatures() async {
    isLoading.value = true;
    try {
      final response = await _apiClient.dio.get('/features');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final Map<String, dynamic> featMap = response.data['features'] ?? {};
        featMap.forEach((key, val) {
          rawFeatures[key] = val;
          features[key] = (val == true || val == 1 || val == '1');
        });
      }
    } catch (e) {
      debugPrint('Error fetching system features: $e');
    } finally {
      isLoading.value = false;
    }
  }

  dynamic getFeatureValue(String key, {dynamic defaultValue}) {
    return rawFeatures[key] ?? defaultValue;
  }

  /// Check if a specific feature is enabled in the system.
  bool isFeatureEnabled(String featureKey, {bool defaultValue = true}) {
    if (!features.containsKey(featureKey)) {
      return defaultValue;
    }
    return features[featureKey] ?? defaultValue;
  }
}
