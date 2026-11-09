import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../data/providers/api_client.dart';

class CustomPageController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  final pages = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPages();
  }

  Future<void> fetchPages() async {
    try {
      isLoading.value = true;
      final response = await _apiClient.dio.get('/pages');
      if (response.data != null && response.data is List) {
        pages.value = List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      debugPrint('Error fetching custom pages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchPageDetail(String slug) async {
    try {
      final response = await _apiClient.dio.get('/pages/$slug');
      if (response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching page detail: $e');
    }
    return null;
  }
}
