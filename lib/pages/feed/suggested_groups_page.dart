import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../utils/app_theme.dart';
import '../../controllers/groups_controller.dart';
import '../../data/models/group_model.dart';
import './group_details_page.dart';

class SuggestedGroupsPage extends StatelessWidget {
  const SuggestedGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GroupsController controller = Get.find<GroupsController>();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('discover_groups'.tr),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        foregroundColor: AppColors.textMain,
      ),
      body: Obx(() {
        if (controller.suggestedGroups.isEmpty && !controller.isLoading.value) {
          return Center(child: Text('no_suggestions_found'.tr));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.suggestedGroups.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final group = controller.suggestedGroups[index];
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
            ElevatedButton(
              onPressed: () => Get.to(() => GroupDetailsPage(groupId: group.id)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('join'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
