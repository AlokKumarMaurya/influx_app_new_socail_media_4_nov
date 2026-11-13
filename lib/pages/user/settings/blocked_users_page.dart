import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../../controllers/user_settings_controller.dart';
import '../../../utils/app_theme.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserSettingsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('blocked_people'.tr, style: AppTextStyles.h3),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchBlockedUsers(),
        child: Obx(() {
          if (controller.blockedUsers.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: Get.height * 0.3),
                  Center(child: Text('no_blocked_users'.tr)),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            itemCount: controller.blockedUsers.length,
            itemBuilder: (context, index) {
              final user = controller.blockedUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['avatar'] != null
                      ? NetworkImage(user['avatar'])
                      : null,
                  child: user['avatar'] == null ? const Icon(Icons.person) : null,
                ),
                title: Text(user['name'] ?? ''),
                subtitle: Text('@${user['username'] ?? ''}'),
                trailing: ElevatedButton(
                  onPressed: () => controller.unblockUser(user['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                  ),
                  child: Text('unblock'.tr),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
