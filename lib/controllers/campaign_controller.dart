import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../data/models/campaign_model.dart';
import '../data/services/discover_service.dart';
import '../utils/app_theme.dart';

class CampaignController extends GetxController {
  final DiscoverService _discoverService = DiscoverService();

  final campaigns = <CampaignModel>[].obs;
  final myCampaigns = <CampaignModel>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  final hasMore = false.obs;

  // Filter/Search parameters
  final selectedNiche = 'All'.obs;
  final selectedType = 'All'.obs;
  final searchQuery = ''.obs;

  // Form Fields
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final nicheController = TextEditingController();
  final budgetFromController = TextEditingController();
  final budgetToController = TextEditingController();
  
  final selectedPlatforms = <String>[].obs;
  final selectedMediaType = 'image'.obs; // image, video, both, none
  final selectedStatus = 'active'.obs; // active, draft, closed
  final selectedTypeField = 'campaign'.obs; // portfolio, campaign, collab
  final selectedCategoryField = 'Fashion'.obs;

  final mediaFiles = <File>[].obs;
  final ImagePicker _picker = ImagePicker();

  // Detail view fields
  final campaignDetails = Rxn<CampaignModel>();

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    nicheController.dispose();
    budgetFromController.dispose();
    budgetToController.dispose();
    super.onClose();
  }

  // Load public campaigns
  Future<void> fetchCampaigns({bool isRefresh = false}) async {
    if (isLoading.value) return;
    if (isRefresh) {
      _currentPage = 1;
      campaigns.clear();
    }
    isLoading.value = true;

    try {
      final res = await _discoverService.getCampaigns(
        niche: selectedNiche.value,
        search: searchQuery.value,
        type: selectedType.value,
        page: _currentPage,
      );

      final newCampaigns = res['campaigns'] as List<CampaignModel>;
      campaigns.addAll(newCampaigns);
      _currentPage = res['currentPage'] as int;
      _lastPage = res['lastPage'] as int;
      hasMore.value = _currentPage < _lastPage;
    } catch (e) {
      Get.log('Error fetching campaigns: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load creator's own campaigns
  Future<void> fetchMyCampaigns({bool isRefresh = false}) async {
    if (isLoading.value) return;
    if (isRefresh) {
      _currentPage = 1;
      myCampaigns.clear();
    }
    isLoading.value = true;

    try {
      final res = await _discoverService.getMyCampaigns(page: _currentPage);
      final newCampaigns = res['campaigns'] as List<CampaignModel>;
      myCampaigns.addAll(newCampaigns);
      _currentPage = res['currentPage'] as int;
      _lastPage = res['lastPage'] as int;
      hasMore.value = _currentPage < _lastPage;
    } catch (e) {
      Get.log('Error fetching my campaigns: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch campaign details
  Future<void> fetchCampaignDetails(int id) async {
    isLoading.value = true;
    campaignDetails.value = null;
    try {
      final res = await _discoverService.getCampaignDetails(id);
      campaignDetails.value = res;
    } catch (e) {
      Get.log('Error fetching campaign details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Pick media
  Future<void> pickMedia() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        mediaFiles.addAll(picked.map((x) => File(x.path)));
      }
    } catch (e) {
      Get.log('Error picking images: $e');
    }
  }

  // Toggle platform selection
  void togglePlatform(String platform) {
    if (selectedPlatforms.contains(platform)) {
      selectedPlatforms.remove(platform);
    } else {
      selectedPlatforms.add(platform);
    }
  }

  // Initialize form for editing
  void initForm(CampaignModel? campaign) {
    mediaFiles.clear();
    if (campaign == null) {
      titleController.clear();
      descriptionController.clear();
      nicheController.clear();
      budgetFromController.clear();
      budgetToController.clear();
      selectedPlatforms.clear();
      selectedMediaType.value = 'image';
      selectedStatus.value = 'active';
      selectedTypeField.value = 'campaign';
      selectedCategoryField.value = 'Fashion';
    } else {
      titleController.text = campaign.title;
      descriptionController.text = campaign.description ?? '';
      nicheController.text = campaign.niche ?? '';
      budgetFromController.text = campaign.budgetFrom?.toString() ?? '';
      budgetToController.text = campaign.budgetTo?.toString() ?? '';
      selectedPlatforms.value = List<String>.from(campaign.platforms);
      selectedMediaType.value = campaign.mediaType;
      selectedStatus.value = campaign.status;
      selectedTypeField.value = campaign.type;
      
      final niche = campaign.niche ?? 'Fashion';
      final matchedCategory = ['Fashion', 'Tech', 'Food', 'Travel', 'Fitness', 'Beauty', 'Finance']
          .firstWhere((cat) => cat.toLowerCase() == niche.toLowerCase(), orElse: () => 'Fashion');
      selectedCategoryField.value = matchedCategory;
    }
  }

  // Create campaign
  Future<void> createCampaign() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('validation_error'.tr, 'title_is_required'.tr,
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    isSubmitting.value = true;

    try {
      final budgetFrom = double.tryParse(budgetFromController.text);
      final budgetTo = double.tryParse(budgetToController.text);

      await _discoverService.createCampaign(
        title: titleController.text.trim(),
        type: selectedTypeField.value,
        mediaType: selectedMediaType.value,
        status: selectedStatus.value,
        description: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
        niche: selectedCategoryField.value,
        budgetFrom: budgetFrom,
        budgetTo: budgetTo,
        platforms: selectedPlatforms.toList(),
        mediaFiles: mediaFiles.toList(),
      );

      Get.back();
      Get.snackbar('success'.tr, 'campaign_created_successfully'.tr,
          backgroundColor: AppColors.success, colorText: Colors.white);
      fetchMyCampaigns(isRefresh: true);
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'].toString();
        } else if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'connection_timed_out'.tr;
        }
      }
      Get.snackbar('error'.tr, errorMessage,
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  // Update campaign
  Future<void> updateCampaign(int id) async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('validation_error'.tr, 'title_is_required'.tr,
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    isSubmitting.value = true;

    try {
      final budgetFrom = double.tryParse(budgetFromController.text);
      final budgetTo = double.tryParse(budgetToController.text);

      await _discoverService.updateCampaign(
        id,
        title: titleController.text.trim(),
        type: selectedTypeField.value,
        mediaType: selectedMediaType.value,
        status: selectedStatus.value,
        description: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
        niche: selectedCategoryField.value,
        budgetFrom: budgetFrom,
        budgetTo: budgetTo,
        platforms: selectedPlatforms.toList(),
        mediaFiles: mediaFiles.toList(),
      );

      Get.back();
      Get.snackbar('success'.tr, 'campaign_updated_successfully'.tr,
          backgroundColor: AppColors.success, colorText: Colors.white);
      fetchCampaignDetails(id);
      fetchMyCampaigns(isRefresh: true);
    } catch (e) {
      Get.snackbar('error'.tr, '${'failed_to_update_campaign'.tr}: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  // Delete Campaign
  Future<void> deleteCampaign(int id) async {
    isLoading.value = true;
    try {
      await _discoverService.deleteCampaign(id);
      Get.back(); // close details or edit screen
      Get.snackbar('success'.tr, 'campaign_deleted_successfully'.tr,
          backgroundColor: AppColors.success, colorText: Colors.white);
      fetchMyCampaigns(isRefresh: true);
      fetchCampaigns(isRefresh: true);
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_delete_campaign'.tr,
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Delete media item
  Future<void> deleteMedia(int campaignId, int mediaId) async {
    try {
      await _discoverService.deleteCampaignMedia(campaignId, mediaId);
      if (campaignDetails.value != null && campaignDetails.value!.id == campaignId) {
        campaignDetails.value!.media.removeWhere((m) => m.id == mediaId);
        campaignDetails.refresh();
      }
      Get.snackbar('success'.tr, 'media_removed_successfully'.tr,
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_delete_media'.tr,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
