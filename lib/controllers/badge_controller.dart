import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import '../data/providers/api_client.dart';
import '../data/models/badge_model.dart';
import '../utils/app_theme.dart';

class BadgeController extends GetxController {
  final ApiClient _apiClient = ApiClient();

  final RxBool isLoading = true.obs;
  final RxBool isBuying = false.obs;
  final RxBool featureEnabled = true.obs;

  final RxDouble walletBalance = 0.0.obs;
  final RxString formattedWallet = '0.00'.obs;
  final RxString currencySymbol = '\$'.obs;
  final Rxn<BadgeModel> equippedBadge = Rxn<BadgeModel>();

  final RxList<BadgeModel> availableBadges = <BadgeModel>[].obs;
  final RxList<UserBadgeModel> userBadges = <UserBadgeModel>[].obs;
  final Rxn<StorageInfoModel> storageInfo = Rxn<StorageInfoModel>();

  @override
  void onInit() {
    super.onInit();
    fetchBadges();
  }

  Future<void> fetchBadges() async {
    isLoading.value = true;
    try {
      final response = await _apiClient.dio.get('/badges');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data;
        featureEnabled.value = data['feature_enabled'] ?? true;
        currencySymbol.value = data['currency_symbol'] ?? '\$';
        walletBalance.value = (data['wallet_balance'] != null)
            ? double.parse(data['wallet_balance'].toString())
            : 0.0;
        formattedWallet.value = data['formatted_wallet'] ?? '0.00';

        if (data['equipped_badge'] != null) {
          equippedBadge.value = BadgeModel.fromJson(data['equipped_badge']);
        } else {
          equippedBadge.value = null;
        }

        if (data['available_badges'] != null) {
          final list = (data['available_badges'] as List)
              .map((e) => BadgeModel.fromJson(e))
              .toList();
          availableBadges.assignAll(list);
        }

        if (data['user_badges'] != null) {
          final uList = (data['user_badges'] as List)
              .map((e) => UserBadgeModel.fromJson(e))
              .toList();
          userBadges.assignAll(uList);
        }

        if (data['storage_info'] != null) {
          storageInfo.value = StorageInfoModel.fromJson(data['storage_info']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching badges: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> buyBadge(BadgeModel badge) async {
    isBuying.value = true;
    try {
      final response = await _apiClient.dio.post('/badges/${badge.id}/buy');
      if (response.statusCode == 200 && response.data['success'] == true) {
        Get.snackbar(
          'Success',
          response.data['message'] ?? 'Badge purchased successfully!',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        await fetchBadges();
      }
    } catch (e) {
      Get.snackbar(
        'Purchase Failed',
        _parseErrorMessage(e),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isBuying.value = false;
    }
  }

  Future<void> equipBadge(int badgeId) async {
    try {
      final response = await _apiClient.dio.post('/badges/$badgeId/equip');
      if (response.statusCode == 200 && response.data['success'] == true) {
        Get.snackbar(
          'Success',
          response.data['message'] ?? 'Badge equipped!',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        await fetchBadges();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        _parseErrorMessage(e),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> unequipBadge() async {
    try {
      final response = await _apiClient.dio.post('/badges/unequip');
      if (response.statusCode == 200 && response.data['success'] == true) {
        Get.snackbar(
          'Success',
          response.data['message'] ?? 'Badge unequipped!',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        await fetchBadges();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        _parseErrorMessage(e),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  String _parseErrorMessage(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        if (data['errors'] != null && data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
          final firstErrList = (data['errors'] as Map).values.first;
          if (firstErrList is List && firstErrList.isNotEmpty) {
            return firstErrList.first.toString();
          }
        }
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
    }
    return e.toString().replaceAll('Exception: ', '');
  }
}
