import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../utils/app_theme.dart';
import '../../data/providers/api_client.dart';
import '../../controllers/feed_controller.dart';

class CountryPickerSheet {
  static final GetStorage _storage = GetStorage();

  static String getSelectedCountryCode() {
    return _storage.read('selected_country') as String? ?? 'all';
  }

  static String getSelectedCountryName() {
    final code = getSelectedCountryCode();
    if (code == 'all') return 'all_countries'.tr;
    final savedName = _storage.read('selected_country_name') as String?;
    if (savedName != null && savedName.isNotEmpty) return savedName;
    return code.toUpperCase();
  }

  static String getSelectedCountryFlag() {
    final code = getSelectedCountryCode();
    if (code == 'all') return '🌐';
    final savedFlag = _storage.read('selected_country_flag') as String?;
    if (savedFlag != null && savedFlag.isNotEmpty) return savedFlag;
    return '🏳️';
  }

  static void show(BuildContext context) {
    final RxString selectedCountry = (getSelectedCountryCode()).obs;
    final RxList<Map<String, String>> countryList = <Map<String, String>>[
      {'code': 'all', 'name': 'all_countries'.tr, 'flag': '🌐'},
    ].obs;
    final RxBool isLoading = true.obs;

    ApiClient().dio.get('/countries').then((response) {
      if (response.data != null && response.data['data'] != null) {
        final list = response.data['data'] as List;
        final formatted = list.map((item) => {
          'code': item['code'].toString(),
          'name': item['name'].toString(),
          'flag': (item['flag'] ?? '🏳️').toString(),
        }).toList();

        countryList.value = [
          {'code': 'all', 'name': 'all_countries'.tr, 'flag': '🌐'},
          ...formatted,
        ];
      }
    }).catchError((e) {
      Get.log('Error fetching country list: $e');
    }).whenComplete(() {
      isLoading.value = false;
    });

    final RxString searchQuery = ''.obs;

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'filter_by_country'.tr,
                style: AppTextStyles.h4,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                onChanged: (val) => searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'search_country'.tr,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  filled: true,
                  fillColor: AppColors.isDark ? Colors.white10 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (isLoading.value && countryList.length <= 1) {
                  return const Center(child: CircularProgressIndicator());
                }
                final query = searchQuery.value.toLowerCase().trim();
                final filtered = countryList.where((item) {
                  if (query.isEmpty) return true;
                  final name = (item['name'] ?? '').toLowerCase();
                  final code = (item['code'] ?? '').toLowerCase();
                  return name.contains(query) || code.contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'no_country_found'.tr,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final code = item['code'] ?? 'all';
                    final name = item['name'] ?? '';
                    final flag = item['flag'] ?? '🌐';
                    final isSelected = selectedCountry.value.toLowerCase() == code.toLowerCase();

                    return ListTile(
                      leading: Text(flag, style: const TextStyle(fontSize: 22)),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.textMain,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                          : null,
                      onTap: () {
                        selectedCountry.value = code;
                        _storage.write('selected_country', code);
                        _storage.write('selected_country_name', name);
                        _storage.write('selected_country_flag', flag);
                        _storage.write('selected_country_chosen', true);
                        Get.back();
                        if (Get.isRegistered<FeedController>()) {
                          Get.find<FeedController>().loadFeed();
                        }
                        Get.snackbar(
                          'country_filter_updated'.tr,
                          '${'showing_content_for'.tr} $name',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
