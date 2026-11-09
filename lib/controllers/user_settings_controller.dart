import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/user_model.dart';
import '../data/models/profile_custom_field_model.dart';
import '../data/services/settings_service.dart';
import 'auth_controller.dart';

class UserSettingsController extends GetxController {
  final SettingsService _settingsService = Get.find<SettingsService>();
  final AuthController _authController = Get.find<AuthController>();

  var isLoading = false.obs;
  var sessions = <Map<String, dynamic>>[].obs;
  var blockedUsers = <Map<String, dynamic>>[].obs;

  // General Settings Form
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final countryController = TextEditingController();
  final stateController = TextEditingController();
  final cityController = TextEditingController();
  final zipCodeController = TextEditingController();
  final addressController = TextEditingController();
  final workController = TextEditingController();
  final educationController = TextEditingController();
  final websiteController = TextEditingController();
  final locationController = TextEditingController();
  
  var selectedGender = Rx<String?>(null);
  var selectedBirthDate = Rx<DateTime?>(null);

  // Profile Custom Fields
  var profileCustomFields = <ProfileCustomFieldModel>[].obs;
  var customFieldControllers = <String, TextEditingController>{}.obs;
  var customFieldSelectedOptions = <String, Rx<String?>>{}.obs;
  var customFieldCheckboxOptions = <String, RxList<String>>{}.obs;

  // Notification Settings Rx
  var notifyFriendRequests = true.obs;
  var notifyMessages = true.obs;
  var notifyComments = true.obs;
  var notifyLikes = true.obs;
  var notifyShares = true.obs;
  var notifyGroupActivity = true.obs;
  var notifyMentions = true.obs;
  var notifyEmail = false.obs;

  // Privacy Settings Rx
  var privacyProfile = 'public'.obs;
  var privacyPosts = 'public'.obs;
  var privacyFriendsList = 'public'.obs;
  var privacyPhotos = 'public'.obs;
  var privacySearchVisible = true.obs;
  var privacyOnlineStatus = true.obs;

  // Profile Field Privacy Rx
  final RxMap<String, String> fieldPrivacy = <String, String>{}.obs;

  String getFieldPrivacy(String field) {
    if (fieldPrivacy.containsKey(field)) return fieldPrivacy[field]!;
    final user = _authController.user.value;
    if (user != null) return user.getFieldPrivacy(field);
    const sensitive = ['email', 'phone', 'birth_date', 'address', 'zip_code'];
    return sensitive.contains(field) ? 'only_me' : 'public';
  }

  void setFieldPrivacy(String field, String val) {
    fieldPrivacy[field] = val;
  }

  // KYC Rx
  var kycStatus = 'none'.obs;
  var kycDetails = Rx<Map<String, dynamic>?>(null);
  var kycDocumentTypes = <Map<String, dynamic>>[].obs;
  var kycFields = <Map<String, dynamic>>[].obs;
  final kycDocNumberController = TextEditingController();
  var selectedKycType = 'id_card'.obs;
  var kycFrontFile = Rx<File?>(null);
  var kycBackFile = Rx<File?>(null);
  var kycSelfieFile = Rx<File?>(null);

  final dynamicFieldControllers = <String, TextEditingController>{}.obs;
  final dynamicFieldFiles = <String, Rx<File?>>{}.obs;
  final dynamicSelectValues = <String, RxString>{}.obs;

  // Password Deletion
  final deletePasswordController = TextEditingController();
  final deleteConfirmController = TextEditingController();

  // Professional Profile
  var profileType = 'user'.obs;
  var businessStatus = Rx<String?>(null);
  var businessName = ''.obs;
  var businessReg = ''.obs;
  final businessNameController = TextEditingController();
  final businessRegController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    initFields();
    ever(_authController.user, (_) {
      initFields();
    });
    fetchSessions();
    fetchBlockedUsers();
    fetchKycStatus();
    fetchProfessionalStatus();
    fetchProfileCustomFields();
  }

  void _syncCustomFieldsWithUser() {
    final user = _authController.user.value;
    final savedData = user?.customFieldsData ?? {};

    for (var f in profileCustomFields) {
      final savedVal = savedData[f.name];
      if (['select', 'radio'].contains(f.type)) {
        customFieldSelectedOptions[f.name] = Rx<String?>(savedVal?.toString());
      } else if (f.type == 'checkbox') {
        List<String> list = [];
        if (savedVal is List) {
          list = savedVal.map((e) => e.toString()).toList();
        }
        customFieldCheckboxOptions[f.name] = RxList<String>(list);
      } else {
        if (customFieldControllers.containsKey(f.name)) {
          customFieldControllers[f.name]!.text = savedVal?.toString() ?? '';
        } else {
          customFieldControllers[f.name] = TextEditingController(text: savedVal?.toString() ?? '');
        }
      }
    }
  }

  Future<void> fetchProfileCustomFields() async {
    try {
      final raw = await _settingsService.getProfileCustomFields();
      profileCustomFields.value = raw.map((e) => ProfileCustomFieldModel.fromJson(e)).toList();
      _syncCustomFieldsWithUser();
    } catch (e) {
      Get.log('Failed to fetch profile custom fields: $e');
    }
  }

  void initFields() {
    final user = _authController.user.value;
    if (user != null) {
      nameController.text = user.name;
      usernameController.text = user.username ?? '';
      emailController.text = user.email ?? '';
      phoneController.text = user.phone ?? '';
      bioController.text = user.bio ?? '';
      countryController.text = user.country ?? '';
      stateController.text = user.state ?? '';
      cityController.text = user.city ?? '';
      zipCodeController.text = user.zipCode ?? '';
      addressController.text = user.address ?? '';
      workController.text = user.work ?? '';
      educationController.text = user.education ?? '';
      websiteController.text = user.website ?? '';
      locationController.text = user.location ?? '';
      
      selectedGender.value = user.gender;
      selectedBirthDate.value = user.birthDate;

      notifyFriendRequests.value = user.notifyFriendRequests;
      notifyMessages.value = user.notifyMessages;
      notifyComments.value = user.notifyComments;
      notifyLikes.value = user.notifyLikes;
      notifyShares.value = user.notifyShares;
      notifyGroupActivity.value = user.notifyGroupActivity;
      notifyMentions.value = user.notifyMentions;
      notifyEmail.value = user.notifyEmail;

      privacyProfile.value = user.privacyProfile;
      privacyPosts.value = user.privacyPosts;
      privacyFriendsList.value = user.privacyFriendsList;
      privacyPhotos.value = user.privacyPhotos;
      privacySearchVisible.value = user.privacySearchVisible;
      privacyOnlineStatus.value = user.privacyOnlineStatus;

      if (user.profileFieldPrivacy.isNotEmpty) {
        fieldPrivacy.assignAll(user.profileFieldPrivacy.map((k, v) => MapEntry(k, v.toString())));
      }

      _syncCustomFieldsWithUser();
    }
  }

  Future<void> updateGeneral() async {
    try {
      isLoading.value = true;
      final Map<String, dynamic> data = {
        'name': nameController.text,
        'username': usernameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'gender': selectedGender.value,
        'birth_date': selectedBirthDate.value?.toIso8601String().split('T')[0],
        'bio': bioController.text,
        'country': countryController.text,
        'state': stateController.text,
        'city': cityController.text,
        'zip_code': zipCodeController.text,
        'address': addressController.text,
        'work': workController.text,
        'education': educationController.text,
        'website': websiteController.text,
        'location': locationController.text,
        'field_privacy': Map<String, String>.from(fieldPrivacy),
      };

      final customFieldsPayload = <String, dynamic>{};
      for (var f in profileCustomFields) {
        if (['select', 'radio'].contains(f.type)) {
          customFieldsPayload[f.name] = customFieldSelectedOptions[f.name]?.value;
        } else if (f.type == 'checkbox') {
          customFieldsPayload[f.name] = customFieldCheckboxOptions[f.name]?.toList();
        } else {
          customFieldsPayload[f.name] = customFieldControllers[f.name]?.text;
        }
      }
      data['custom_fields'] = customFieldsPayload;

      final result = await _settingsService.updateGeneral(data);
      if (result['success']) {
        _authController.user.value = UserModel.fromJson(result['data']);
        Get.snackbar('success'.tr, 'general_settings_updated'.tr);
      } else {
        Get.snackbar('error'.tr, result['message'] ?? 'failed_to_save'.tr);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateNotifications() async {
    try {
      isLoading.value = true;
      final data = {
        'notify_friend_requests': notifyFriendRequests.value,
        'notify_messages': notifyMessages.value,
        'notify_comments': notifyComments.value,
        'notify_likes': notifyLikes.value,
        'notify_shares': notifyShares.value,
        'notify_group_activity': notifyGroupActivity.value,
        'notify_mentions': notifyMentions.value,
        'notify_email': notifyEmail.value,
      };

      final result = await _settingsService.updateNotifications(data);
      if (result['success']) {
        Get.snackbar('Success', 'Notification settings updated!');
        // Update local user model
        _authController.user.value = _authController.user.value?.copyWith(
          notifyFriendRequests: notifyFriendRequests.value,
          notifyMessages: notifyMessages.value,
          notifyComments: notifyComments.value,
          notifyLikes: notifyLikes.value,
          notifyShares: notifyShares.value,
          notifyGroupActivity: notifyGroupActivity.value,
          notifyMentions: notifyMentions.value,
          notifyEmail: notifyEmail.value,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePrivacy() async {
    try {
      isLoading.value = true;
      final data = {
        'privacy_profile': privacyProfile.value,
        'privacy_posts': privacyPosts.value,
        'privacy_friends_list': privacyFriendsList.value,
        'privacy_photos': privacyPhotos.value,
        'privacy_search_visible': privacySearchVisible.value,
        'privacy_online_status': privacyOnlineStatus.value,
      };

      final result = await _settingsService.updatePrivacy(data);
      if (result['success']) {
        Get.snackbar('Success', 'Privacy settings updated!');
        // Update local user model
        _authController.user.value = _authController.user.value?.copyWith(
          privacyProfile: privacyProfile.value,
          privacyPosts: privacyPosts.value,
          privacyFriendsList: privacyFriendsList.value,
          privacyPhotos: privacyPhotos.value,
          privacySearchVisible: privacySearchVisible.value,
          privacyOnlineStatus: privacyOnlineStatus.value,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSessions() async {
    final result = await _settingsService.getSessions();
    if (result['success']) {
      sessions.assignAll(List<Map<String, dynamic>>.from(result['data']));
    }
  }

  Future<void> revokeSession(int id) async {
    final result = await _settingsService.revokeSession(id);
    if (result['success']) {
      sessions.removeWhere((s) => s['id'] == id);
      Get.snackbar('Success', 'Session revoked');
    }
  }

  Future<void> revokeAllOthers() async {
    final result = await _settingsService.revokeAllSessions();
    if (result['success']) {
      sessions.removeWhere((s) => s['is_current'] == false);
      Get.snackbar('Success', 'All other sessions revoked');
    }
  }

  Future<void> fetchBlockedUsers() async {
    final result = await _settingsService.getBlockedUsers();
    if (result['success']) {
      blockedUsers.assignAll(List<Map<String, dynamic>>.from(result['data']));
    }
  }

  Future<void> unblockUser(int id) async {
    final result = await _settingsService.unblockUser(id);
    if (result['success']) {
      blockedUsers.removeWhere((u) => u['id'] == id);
      Get.snackbar('success'.tr, 'user_unblocked_successfully'.tr);
    }
  }

  Map<String, dynamic>? get selectedDocTypeConfig {
    if (kycDocumentTypes.isEmpty) return null;
    return kycDocumentTypes.firstWhereOrNull(
      (dt) => dt['slug'] == selectedKycType.value || dt['id'].toString() == selectedKycType.value,
    );
  }

  List<Map<String, dynamic>> get currentApplicableFields {
    final docConfig = selectedDocTypeConfig;
    final docId = docConfig?['id'];
    return kycFields.where((f) {
      final targetId = f['document_type_id'];
      return targetId == null || targetId == docId;
    }).toList();
  }

  Future<void> fetchKycStatus() async {
    final result = await _settingsService.getKycStatus();
    if (result['success']) {
      final data = result['data'];
      kycStatus.value = data['status'] ?? 'none';
      kycDetails.value = data['details'];

      if (data['document_types'] != null) {
        final list = List<Map<String, dynamic>>.from(data['document_types']);
        kycDocumentTypes.value = list;
        if (list.isNotEmpty && !list.any((dt) => dt['slug'] == selectedKycType.value)) {
          selectedKycType.value = list.first['slug'];
        }
      }

      if (data['fields'] != null) {
        final list = List<Map<String, dynamic>>.from(data['fields']);
        kycFields.value = list;
        for (final field in list) {
          final key = field['name'] as String;
          dynamicFieldControllers[key] ??= TextEditingController();
          dynamicFieldFiles[key] ??= Rx<File?>(null);
          dynamicSelectValues[key] ??= RxString('');
        }
      }
    }
  }

  Future<void> pickKycImage(String type) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (type == 'front') kycFrontFile.value = File(image.path);
      if (type == 'back') kycBackFile.value = File(image.path);
      if (type == 'selfie') kycSelfieFile.value = File(image.path);
    }
  }

  Future<void> pickDynamicFile(String key) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
    );
    if (result != null && result.files.single.path != null) {
      dynamicFieldFiles[key]?.value = File(result.files.single.path!);
    }
  }

  Future<void> submitKyc() async {
    final config = selectedDocTypeConfig;
    final numReq = config?['document_number_requirement'] ?? 'required';
    final frontReq = config?['front_requirement'] ?? 'required';
    final backReq = config?['back_requirement'] ?? 'optional';
    final selfieReq = config?['selfie_requirement'] ?? 'required';

    if (numReq == 'required' && kycDocNumberController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'please_enter_document_number'.tr);
      return;
    }
    if (frontReq == 'required' && kycFrontFile.value == null) {
      Get.snackbar('error'.tr, 'please_upload_front_photo'.tr);
      return;
    }
    if (backReq == 'required' && kycBackFile.value == null) {
      Get.snackbar('error'.tr, 'please_upload_back_photo'.tr);
      return;
    }
    if (selfieReq == 'required' && kycSelfieFile.value == null) {
      Get.snackbar('error'.tr, 'please_upload_selfie'.tr);
      return;
    }

    // Validate dynamic fields
    final customFields = <String, dynamic>{};
    final customFiles = <String, File>{};

    for (final field in currentApplicableFields) {
      final key = field['name'] as String;
      final isRequired = field['is_required'] == true;
      final type = field['type'] as String;

      if (type == 'file') {
        final file = dynamicFieldFiles[key]?.value;
        if (isRequired && file == null) {
          Get.snackbar('error'.tr, 'please_attach_required_file'.trParams({'field': field['label']?.toString() ?? ''}));
          return;
        }
        if (file != null) {
          customFiles[key] = file;
        }
      } else if (type == 'select' || type == 'radio') {
        final val = dynamicSelectValues[key]?.value ?? '';
        if (isRequired && val.isEmpty) {
          Get.snackbar('error'.tr, 'please_select_field'.trParams({'field': field['label']?.toString() ?? ''}));
          return;
        }
        if (val.isNotEmpty) {
          customFields[key] = val;
        }
      } else {
        final textVal = dynamicFieldControllers[key]?.text.trim() ?? '';
        if (isRequired && textVal.isEmpty) {
          Get.snackbar('error'.tr, 'please_fill_required_field'.trParams({'field': field['label']?.toString() ?? ''}));
          return;
        }
        if (textVal.isNotEmpty) {
          customFields[key] = textVal;
        }
      }
    }

    try {
      isLoading.value = true;
      final result = await _settingsService.submitKyc(
        documentType: selectedKycType.value,
        documentNumber: numReq != 'disabled' ? kycDocNumberController.text.trim() : null,
        documentFront: frontReq != 'disabled' ? kycFrontFile.value : null,
        documentBack: backReq != 'disabled' ? kycBackFile.value : null,
        selfie: selfieReq != 'disabled' ? kycSelfieFile.value : null,
        customFields: customFields,
        customFiles: customFiles,
      );

      if (result['success']) {
        Get.snackbar('success'.tr, result['message'] ?? 'kyc_submitted_successfully'.tr);
        fetchKycStatus();
      } else {
        Get.snackbar('error'.tr, result['message'] ?? 'submission_failed'.tr);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final response = await _apiClient.dio.get('/user');
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data is Map<String, dynamic> && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        if (userData is Map<String, dynamic>) {
          _authController.user.value = UserModel.fromJson(userData);
          initFields();
        }
      }
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }
  }

  Future<void> refreshSettings(int tabIndex) async {
    switch (tabIndex) {
      case 0: // General
      case 1: // Notifications
      case 2: // Privacy
        await refreshProfile();
        break;
      case 4: // Sessions
        await fetchSessions();
        break;
      case 5: // Blocked
        await fetchBlockedUsers();
        break;
      case 6: // KYC
        await fetchKycStatus();
        break;
      case 7: // Professional
        await fetchProfessionalStatus();
        break;
    }
  }

  Future<void> fetchProfessionalStatus() async {
    final result = await _settingsService.getProfessionalStatus();
    if (result['success']) {
      profileType.value = result['data']['profile_type'] ?? 'user';
      businessStatus.value = result['data']['business_status'];
      businessName.value = result['data']['business_name'] ?? '';
      businessReg.value = result['data']['business_registration_number'] ?? '';
      
      businessNameController.text = businessName.value;
      businessRegController.text = businessReg.value;
      
      kycStatus.value = result['data']['kyc_status'] ?? 'none';
    }
  }

  Future<void> upgradeToCreator() async {
    try {
      isLoading.value = true;
      final result = await _settingsService.upgradeToCreator();
      if (result['success']) {
        Get.snackbar('success'.tr, result['message'] ?? 'upgraded_to_creator_successfully'.tr);
        fetchProfessionalStatus();
      } else {
        Get.snackbar('error'.tr, result['message'] ?? 'upgrade_failed'.tr);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> upgradeToBusiness() async {
    if (businessNameController.text.isEmpty) {
      Get.snackbar('error'.tr, 'business_name_required'.tr);
      return;
    }

    try {
      isLoading.value = true;
      final result = await _settingsService.upgradeToBusiness(
        businessName: businessNameController.text,
        businessRegistration: businessRegController.text,
      );
      if (result['success']) {
        Get.snackbar('success'.tr, result['message'] ?? 'upgraded_to_business_successfully'.tr);
        fetchProfessionalStatus();
      } else {
        Get.snackbar('error'.tr, result['message'] ?? 'upgrade_failed'.tr);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    if (deletePasswordController.text.isEmpty) {
      Get.snackbar('error'.tr, 'enter_password_to_confirm'.tr);
      return;
    }

    if (deleteConfirmController.text != 'DELETE') {
      Get.snackbar('error'.tr, 'type_delete_to_confirm'.tr);
      return;
    }

    try {
      isLoading.value = true;
      final result = await _settingsService.deleteAccount(deletePasswordController.text);
      if (result['success']) {
        Get.snackbar('success'.tr, 'account_deleted_successfully'.tr);
        _authController.logout();
      } else {
        Get.snackbar('error'.tr, result['message'] ?? 'deletion_failed'.tr);
      }
    } finally {
      isLoading.value = false;
    }
  }

  final _apiClient = Get.find<SettingsService>().apiClient; // Helper to access dio

  @override
  void onClose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    bioController.dispose();
    countryController.dispose();
    stateController.dispose();
    cityController.dispose();
    zipCodeController.dispose();
    addressController.dispose();
    workController.dispose();
    educationController.dispose();
    websiteController.dispose();
    locationController.dispose();
    kycDocNumberController.dispose();
    deletePasswordController.dispose();
    deleteConfirmController.dispose();
    businessNameController.dispose();
    businessRegController.dispose();
    super.onClose();
  }
}
