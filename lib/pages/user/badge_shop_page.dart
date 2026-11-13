import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../controllers/badge_controller.dart';
import '../../utils/app_theme.dart';
import '../../data/models/badge_model.dart';

class BadgeShopPage extends StatefulWidget {
  const BadgeShopPage({super.key});

  @override
  State<BadgeShopPage> createState() => _BadgeShopPageState();
}

class _BadgeShopPageState extends State<BadgeShopPage>
    with SingleTickerProviderStateMixin {
  late final BadgeController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(BadgeController());
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'profile_badges_and_storage'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!_controller.featureEnabled.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('profile_badges_disabled'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('profile_badges_disabled_desc'.tr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.fetchBadges,
          child: Column(
            children: [
              // Wallet & Storage Header Banner
              _buildHeaderCard(),

              // TabBar
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: 'badge_store'.tr),
                  Tab(text: 'my_badges'.tr),
                ],
              ),

              // TabBar View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildBadgeStoreTab(), _buildMyBadgesTab()],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeaderCard() {
    final storage = _controller.storageInfo.value;
    final equipped = _controller.equippedBadge.value;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (equipped != null && equipped.iconUrl.isNotEmpty)
                    Image.network(
                      equipped.iconUrl,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.verified,
                        color: Colors.amber,
                        size: 24,
                      ),
                    )
                  else
                    const Icon(
                      Icons.shield_outlined,
                      color: Colors.amber,
                      size: 24,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    equipped != null ? equipped.name : 'standard_profile'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'wallet_balance'.tr,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  Text(
                    _controller.formattedWallet.value,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Storage Progress Bar
          if (storage != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.sd_storage_outlined,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'storage_usage'.tr,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  '${storage.formattedUsed} / ${storage.formattedMax} (${storage.usagePercentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (storage.usagePercentage / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  storage.usagePercentage > 90
                      ? Colors.redAccent
                      : Colors.amber,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeStoreTab() {
    final badges = _controller.availableBadges;

    if (badges.isEmpty) {
      return Center(
        child: Text(
          'no_badges_available'.tr,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Image.network(
                    badge.iconUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.shield, color: Colors.amber, size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              badge.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (badge.isOwned)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'owned'.tr,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (badge.description != null &&
                          badge.description!.isNotEmpty)
                        Text(
                          badge.description!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${badge.extraStorageMb} MB ${'extra_storage'.tr}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            badge.formattedPrice,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          if (badge.isOwned && !badge.allowRepurchase)
                            ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                shape: const StadiumBorder(),
                                backgroundColor: Colors.grey.shade300,
                              ),
                              child: Text(
                                badge.ownedCount > 1 ? '${'owned'.tr} (${badge.ownedCount}x)' : 'owned'.tr,
                                style: const TextStyle(fontSize: 12),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _controller.isBuying.value
                                  ? null
                                  : () => _confirmPurchase(badge),
                              icon: const Icon(
                                Icons.shopping_bag_outlined,
                                size: 16,
                              ),
                              label: Text(
                                badge.isOwned ? 'repurchase'.tr : 'buy_badge'.tr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                shape: const StadiumBorder(),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyBadgesTab() {
    final userBadges = _controller.userBadges;

    if (userBadges.isEmpty) {
      return Center(
        child: Text(
          'no_badges_purchased_yet'.tr,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: userBadges.length,
      itemBuilder: (context, index) {
        final ub = userBadges[index];
        final badge = ub.badge;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: ub.isEquipped ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.network(
                    badge.iconUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.shield, color: Colors.amber, size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            badge.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (ub.isEquipped)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'equipped'.tr,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${badge.extraStorageMb} MB ${'extra_storage'.tr}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: !badge.isVisibleOnProfile
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'utility_package_active'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              )
                            : ub.isEquipped
                                ? OutlinedButton(
                                    onPressed: () => _controller.unequipBadge(),
                                    style: OutlinedButton.styleFrom(
                                      shape: const StadiumBorder(),
                                    ),
                                    child: Text(
                                      'unequip'.tr,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () =>
                                        _controller.equipBadge(badge.id),
                                    style: ElevatedButton.styleFrom(
                                      shape: const StadiumBorder(),
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      'equip_on_profile'.tr,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmPurchase(BadgeModel badge) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${'buy'.tr} ${badge.name}?'),
        content: Text(
          'confirm_badge_purchase_msg'.trParams({
            'name': badge.name,
            'price': badge.formattedPrice,
          }),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _controller.buyBadge(badge);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: const StadiumBorder(),
            ),
            child: Text(
              'confirm_purchase'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
