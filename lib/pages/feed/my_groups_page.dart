import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_theme.dart';
import '../../controllers/groups_controller.dart';
import '../../data/models/group_model.dart';
import './group_details_page.dart';

class MyGroupsPage extends StatelessWidget {
  const MyGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GroupsController controller = Get.find<GroupsController>();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('your_groups'.tr),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        foregroundColor: AppColors.textMain,
      ),
      body: Obx(() {
        if (controller.myGroups.isEmpty && !controller.isLoading.value) {
          return Center(child: Text('no_groups_joined_yet'.tr));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.myGroups.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final group = controller.myGroups[index];
            return _buildGroupTile(group);
          },
        );
      }),
    );
  }

  Widget _buildGroupTile(GroupModel group) {
    return InkWell(
      onTap: () => Get.to(() => GroupDetailsPage(groupId: group.id)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(group.avatar ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  Text('${group.memberCount} ${'members'.tr}', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
