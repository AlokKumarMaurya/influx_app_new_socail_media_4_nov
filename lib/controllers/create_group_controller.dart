import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import '../data/services/group_service.dart';
import '../pages/feed/group_details_page.dart';

class CreateGroupController extends GetxController {
  final GroupService _groupService = Get.find<GroupService>();

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  var privacy = 'public'.obs;
  var isLoading = false.obs;
  
  File? avatarFile;
  File? coverFile;

  Future<void> createGroup() async {
    if (nameController.text.isEmpty) {
      Get.snackbar('error'.tr, 'name_is_required'.tr, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      isLoading.value = true;
      
      final Map<String, dynamic> data = {
        'name': nameController.text,
        'description': descriptionController.text,
        'privacy': privacy.value,
      };

      if (avatarFile != null) {
        data['avatar'] = await MultipartFile.fromFile(
          avatarFile!.path,
          filename: avatarFile!.path.split('/').last,
        );
      }

      if (coverFile != null) {
        data['cover_photo'] = await MultipartFile.fromFile(
          coverFile!.path,
          filename: coverFile!.path.split('/').last,
        );
      }

      final formData = FormData.fromMap(data);
      final result = await _groupService.createGroup(formData);
      
      if (result['success']) {
        Get.snackbar('success'.tr, 'group_created_success'.tr, 
          backgroundColor: Colors.green, 
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
        );
        Future.delayed(const Duration(milliseconds: 1500), () {
          Get.off(() => GroupDetailsPage(groupId: result['data']['id']));
        });
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'error_creating_group'.tr, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
