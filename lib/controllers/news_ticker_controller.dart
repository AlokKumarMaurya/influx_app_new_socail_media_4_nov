import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../data/providers/api_client.dart';

class NewsTickerController extends GetxController {
  final Dio _dio = ApiClient().dio;

  final isEnabled = false.obs;
  final tickerType = 'custom'.obs;
  final tickerText = ''.obs;
  final tickerLink = ''.obs;
  final blogItems = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNewsTicker();
  }

  Future<void> fetchNewsTicker() async {
    isLoading.value = true;
    try {
      final response = await _dio.get('/news-ticker');
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        isEnabled.value = data['app_enabled'] ?? false;
        tickerType.value = data['type'] ?? 'custom';
        tickerText.value = data['text'] ?? '';
        tickerLink.value = data['link'] ?? '';

        if (data['items'] != null && data['items'] is List) {
          blogItems.value = (data['items'] as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        } else {
          blogItems.clear();
        }
      }
    } catch (e) {
      Get.log('Fetch news ticker error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
