import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/creator_controller.dart';
import '../../utils/app_theme.dart';

class CreatorDashboardPage extends StatelessWidget {
  const CreatorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreatorController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.textMain, size: 24),
          onPressed: () => Get.back(),
        ),
        title: Text('creator_dashboard'.tr, style: AppTextStyles.h3),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(controller),
                const SizedBox(height: 20),
                _buildPerformanceChart(controller),
                const SizedBox(height: 20),
                _buildTopPostsSection(controller),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════
  // Stats Grid (2x2)
  // ═══════════════════════════════════════

  Widget _buildStatsGrid(CreatorController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'total_views'.tr,
                controller.totalViews.value,
                HugeIcons.strokeRoundedView,
                const Color(0xFF3B82F6),
                const Color(0xFFDBEAFE),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'total_reach'.tr,
                controller.totalReach.value,
                HugeIcons.strokeRoundedUserGroup,
                const Color(0xFF10B981),
                const Color(0xFFD1FAE5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'interactions'.tr,
                controller.totalInteractions.value,
                HugeIcons.strokeRoundedFavourite,
                const Color(0xFFEC4899),
                const Color(0xFFFCE7F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'posts'.tr,
                controller.totalPosts.value,
                HugeIcons.strokeRoundedNote,
                const Color(0xFFF59E0B),
                const Color(0xFFFEF3C7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, dynamic icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(icon: icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            _formatNumber(value),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // Performance Chart
  // ═══════════════════════════════════════

  Widget _buildPerformanceChart(CreatorController controller) {
    if (controller.chartLabels.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxViews = controller.chartViews.isEmpty
        ? 10.0
        : (controller.chartViews.reduce((a, b) => a > b ? a : b) * 1.3).clamp(5.0, double.infinity);
    final maxReach = controller.chartReach.isEmpty
        ? 10.0
        : (controller.chartReach.reduce((a, b) => a > b ? a : b) * 1.3).clamp(5.0, double.infinity);
    final maxY = maxViews > maxReach ? maxViews : maxReach;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('last_7_days'.tr, style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
              Row(
                children: [
                  _chartLegend(const Color(0xFF3B82F6), 'views'.tr),
                  const SizedBox(width: 12),
                  _chartLegend(const Color(0xFF10B981), 'reach'.tr),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= controller.chartLabels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            controller.chartLabels[idx],
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Views line
                  LineChartBarData(
                    spots: controller.chartViews
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF3B82F6),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          const Color(0xFF3B82F6).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Reach line
                  LineChartBarData(
                    spots: controller.chartReach
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF10B981),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.2),
                          const Color(0xFF10B981).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.cardBg,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    tooltipBorder: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.1)),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isViews = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${isViews ? "views".tr : "reach".tr}: ${spot.y.toInt()}',
                          TextStyle(
                            color: isViews ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ═══════════════════════════════════════
  // Top Posts
  // ═══════════════════════════════════════

  Widget _buildTopPostsSection(CreatorController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('top_performing_posts'.tr, style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (controller.topPosts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedChartHistogram, color: AppColors.textSecondary.withValues(alpha: 0.4), size: 48),
                const SizedBox(height: 12),
                Text('no_posts_yet'.tr, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                Text('start_creating_analytics'.tr, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ),
          )
        else
          ...controller.topPosts.map((post) => _buildPostCard(post)),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final createdAt = DateTime.tryParse(post['created_at'] ?? '') ?? DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post['content'] ?? 'media_status_post'.tr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _postStatChip(HugeIcons.strokeRoundedUserGroup, '${post['reach'] ?? 0}', const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _postStatChip(HugeIcons.strokeRoundedView, '${post['views_count'] ?? 0}', const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _postStatChip(HugeIcons.strokeRoundedFavourite, '${post['reactions_count'] ?? 0}', const Color(0xFFEC4899)),
              const SizedBox(width: 12),
              _postStatChip(HugeIcons.strokeRoundedComment01, '${post['comments_count'] ?? 0}', const Color(0xFF8B5CF6)),
              const Spacer(),
              Text(dateStr, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _postStatChip(dynamic icon, String value, Color color) {
    return Row(
      children: [
        HugeIcon(icon: icon, color: color, size: 14),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ═══════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════

  String _formatNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}
