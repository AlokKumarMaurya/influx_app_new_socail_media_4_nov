import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../utils/url_utils.dart';
import '../../utils/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../data/models/story_model.dart';
import '../../data/models/live_stream_model.dart';
import '../common/custom_network_image.dart';
import '../../pages/story/story_view_page.dart';
import '../../pages/story/create_story_page.dart';
import '../../pages/live/live_room_page.dart';
import '../../pages/user/profile_page.dart';

class StoriesRow extends StatelessWidget {
  final List<StoryGroup> stories;
  final List<LiveStreamModel> liveStreams;

  const StoriesRow({
    super.key,
    required this.stories,
    this.liveStreams = const [],
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = 1 + liveStreams.length + stories.length;
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index == 0) return _buildAddStory();
          final liveIdx = index - 1;
          if (liveIdx < liveStreams.length) {
            return _buildLiveStoryItem(liveStreams[liveIdx]);
          }
          final storyIdx = liveIdx - liveStreams.length;
          return _buildStoryItem(stories[storyIdx], storyIdx);
        },
      ),
    );
  }

  Widget _buildAddStory() {
    final authController = Get.find<AuthController>();
    final user = authController.user.value;

    return GestureDetector(
      onTap: () => Get.to(() => const CreateStoryPage()),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: SizedBox(
                        width: double.infinity,
                        child: user?.avatar != null && user!.avatar!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: UrlUtils.getFullUrl(user.avatar!),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: Icon(Icons.person, color: AppColors.primary, size: 40),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Icon(Icons.person, color: AppColors.primary, size: 40),
                                ),
                              )
                            : Center(
                                child: Icon(Icons.person, color: AppColors.primary, size: 40),
                              ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'add_story'.tr,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 25,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBg, width: 3),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStoryItem(LiveStreamModel live) {
    return GestureDetector(
      onTap: () => Get.to(() => LiveRoomPage(uuid: live.uuid)),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: UrlUtils.getFullUrl(live.thumbnailUrl),
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(color: const Color(0xFF1A1628)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '👁 ${live.viewerCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  live.broadcasterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryItem(StoryGroup group, int index) {
    final lastStory = group.stories.last;

    return GestureDetector(
      onTap: () => Get.to(
        () => StoryViewPage(groups: stories, initialGroupIndex: index),
      ),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Preview Media (Last Story)
              Positioned.fill(child: _buildPreview(lastStory)),
              // Gradient Overlay for Readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      stops: const [0.0, 0.2, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              // User Avatar (Top Left)
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () => Get.to(() => ProfilePage(userId: group.user.id)),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: group.hasUnseenStories
                            ? AppColors.primary
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child:
                            group.user.avatar != null &&
                                group.user.avatar!.isNotEmpty
                            ? CustomNetworkImage(
                                imageUrl: group.user.avatar!,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/img/user_avatar.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              // User Name (Bottom)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  group.user.name.split(' ').first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(StoryModel story) {
    if (story.mediaType == 'text') {
      return Container(
        color: _parseColor(story.bgColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              story.content ?? '',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                fontFamily: story.fontStyle,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (story.mediaType == 'video') {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Icon(Icons.play_circle_outline, color: Colors.white, size: 30),
        ),
      );
    }

    return CustomNetworkImage(
      imageUrl: story.mediaUrl ?? '',
      fit: BoxFit.cover,
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null) return AppColors.primary;
    try {
      String hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
