import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_utils.dart';
import '../../data/models/post_model.dart';
import '../../pages/fan_page/fan_page_profile_page.dart';
import '../../pages/fan_page/jobs/job_apply_sheet.dart';
import '../../pages/fan_page/jobs/job_details_page.dart';
import '../../pages/feed/media_viewer_page.dart';
import '../../pages/live/live_room_page.dart';
import '../common/custom_network_image.dart';
import '../common/video_player_widget.dart';
import './video_preview_box.dart';

class PostCardMedia extends StatelessWidget {
  final PostModel post;
  final bool isSingleView;
  final bool isShared;

  const PostCardMedia({
    super.key,
    required this.post,
    this.isSingleView = false,
    this.isShared = false,
  });

  @override
  Widget build(BuildContext context) {
    if (post.postType == 'live_stream' || post.liveStream != null) {
      return _LiveStreamPostCard(post: post);
    }

    if (post.postType == 'job_post' || post.fanPageJob != null) {
      return _JobPostMediaCard(post: post);
    }

    if (post.media.isEmpty || post.postType == 'color') return const SizedBox.shrink();

    final images = post.media.where((m) => m.fileType == 'image').toList();
    final videos = post.media.where((m) => m.fileType == 'video').toList();

    if (videos.length == 1 && images.isEmpty) {
      return _VideoPlayer(video: videos[0], isSingleView: isSingleView);
    }

    return _MediaGrid(media: post.media, post: post, isShared: isShared);
  }
}

class _LiveStreamPostCard extends StatelessWidget {
  final PostModel post;

  const _LiveStreamPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final live = post.liveStream;
    if (live == null) return const SizedBox.shrink();
    final isLive = live.status == 'live';

    return GestureDetector(
      onTap: () => Get.to(() => LiveRoomPage(uuid: live.uuid)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF14111F),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomNetworkImage(
                imageUrl: UrlUtils.getFullUrl(live.thumbnailUrl),
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLive ? Colors.redAccent : Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: isLive
                                ? HugeIcons.strokeRoundedVideo02
                                : HugeIcons.strokeRoundedClock01,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLive ? 'LIVE NOW' : 'ENDED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (live.isPaid) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedLock,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${live.currencySymbol ?? (Get.isRegistered<SettingsController>() ? Get.find<SettingsController>().currencySymbol.value : '\$')}${live.entryFee.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedView,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isLive ? live.viewerCount : live.peakViewerCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ),
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedPlay,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            live.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${live.broadcasterName} • ${live.category.toUpperCase()}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isLive ? 'Join Live' : 'Watch',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPlayer extends StatelessWidget {
  final PostMediaModel video;
  final bool isSingleView;

  const _VideoPlayer({required this.video, required this.isSingleView});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: isSingleView ? 300 : 220,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          VideoPlayerWidget(
            videoUrl: video.filePath,
            mediaId: video.id,
            autoPlay: isSingleView,
            looping: true,
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${video.viewsCount} views',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<PostMediaModel> media;
  final PostModel post;
  final bool isShared;

  const _MediaGrid({required this.media, required this.post, required this.isShared});

  @override
  Widget build(BuildContext context) {
    if (media.length == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _MediaBox(media: media[0], allMedia: media, post: post, isShared: isShared),
      );
    }
    if (media.length == 2) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Row(children: [
          Expanded(child: _MediaBox(media: media[0], allMedia: media, post: post, isShared: isShared)),
          const SizedBox(width: 2),
          Expanded(child: _MediaBox(media: media[1], allMedia: media, post: post, isShared: isShared)),
        ]),
      );
    }
    if (media.length == 3) {
      return Column(children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _MediaBox(media: media[0], allMedia: media, post: post, isShared: isShared),
        ),
        const SizedBox(height: 2),
        AspectRatio(
          aspectRatio: 16 / 4.5,
          child: Row(children: [
            Expanded(child: _MediaBox(media: media[1], allMedia: media, post: post, isShared: isShared)),
            const SizedBox(width: 2),
            Expanded(child: _MediaBox(media: media[2], allMedia: media, post: post, isShared: isShared)),
          ]),
        ),
      ]);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: media.length > 4 ? 4 : media.length,
      itemBuilder: (context, index) =>
          _MediaBox(media: media[index], allMedia: media, post: post, isShared: isShared),
    );
  }
}

class _MediaBox extends StatelessWidget {
  final PostMediaModel media;
  final List<PostMediaModel> allMedia;
  final PostModel post;
  final bool isShared;

  const _MediaBox({
    required this.media,
    required this.allMedia,
    required this.post,
    required this.isShared,
  });

  @override
  Widget build(BuildContext context) {
    final heroTagPrefix = 'post_${post.id}_media${isShared ? '_shared' : ''}_$hashCode';

    return GestureDetector(
      onTap: () {
        final index = allMedia.indexOf(media);
        Get.to(() => MediaViewerPage(
              media: allMedia,
              initialIndex: index,
              heroTagPrefix: heroTagPrefix,
            ));
      },
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Hero(
          tag: '${heroTagPrefix}_${media.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (media.fileType == 'video')
                VideoPreviewBox(videoUrl: UrlUtils.getFullUrl(media.filePath))
              else
                CustomNetworkImage(imageUrl: media.filePath, fit: BoxFit.cover),
              if (allMedia.length > 4 && allMedia.indexOf(media) == 3)
                Container(
                  color: Colors.black45,
                  child: Center(
                    child: Text(
                      '+${allMedia.length - 4}',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobPostMediaCard extends StatelessWidget {
  final PostModel post;

  const _JobPostMediaCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final job = post.fanPageJob;
    if (job == null) return const SizedBox.shrink();

    final pageName = post.fanPage?.name ?? 'Company';
    final pageSlug = post.fanPage?.slug ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedBriefcase02, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'JOB OPENING',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${job.applicationsCount} applicants',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (job.status == 'active' ? Colors.green : (job.status == 'paused' ? Colors.orange : Colors.grey)).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        job.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: job.status == 'active' ? Colors.green : (job.status == 'paused' ? Colors.orange : Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Job Banner Image if present
          if (job.imageUrl != null && job.imageUrl!.isNotEmpty)
            GestureDetector(
              onTap: () {
                Get.to(() => JobDetailsPage(
                  job: job,
                  pageSlug: pageSlug,
                  pageName: pageName,
                ));
              },
              child: Image.network(
                job.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    Get.to(() => JobDetailsPage(
                      job: job,
                      pageSlug: pageSlug,
                      pageName: pageName,
                    ));
                  },
                  child: Text(
                    job.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 2),
                if (post.fanPage != null)
                  InkWell(
                    onTap: () => Get.to(() => FanPageProfilePage(slug: post.fanPage!.slug)),
                    child: Text(
                      pageName,
                      style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 10),

                // Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPill(HugeIcons.strokeRoundedBriefcase02, job.jobTypeLabel, Colors.indigo),
                    _buildPill(HugeIcons.strokeRoundedHome01, job.workplaceTypeLabel, Colors.teal),
                    if (job.salaryRangeLabel.isNotEmpty)
                      _buildPill(HugeIcons.strokeRoundedWallet01, job.salaryRangeLabel, const Color(0xFF059669)),
                    if (job.location != null && job.location!.isNotEmpty)
                      _buildPill(HugeIcons.strokeRoundedLocation01, job.location!, Colors.blueGrey),
                  ],
                ),
                const SizedBox(height: 14),

                // CTA Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Get.to(() => JobDetailsPage(
                          job: job,
                          pageSlug: pageSlug,
                          pageName: pageName,
                        ));
                      },
                      child: Row(
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedView, color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text('Details', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (job.hasApplied)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Applied', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          if (pageSlug.isEmpty) return;
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => JobApplySheet(
                              pageSlug: pageSlug,
                              job: job,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Apply Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(dynamic icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

