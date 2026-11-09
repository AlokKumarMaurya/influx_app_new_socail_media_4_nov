import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_network_image.dart';
import '../../data/models/fan_page_model.dart';
import '../../data/services/fan_page_service.dart';
import 'fan_page_profile_page.dart';
import 'fan_page_inbox_page.dart';
import 'fan_page_manage_page.dart';

class FanPagesListPage extends StatefulWidget {
  final int initialTabIndex;
  const FanPagesListPage({super.key, this.initialTabIndex = 0});

  @override
  State<FanPagesListPage> createState() => _FanPagesListPageState();
}

class _FanPagesListPageState extends State<FanPagesListPage> with SingleTickerProviderStateMixin {
  final FanPageService _service = FanPageService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<FanPageCategoryModel> _categories = [];
  String? _selectedCategorySlug;

  // Discover state
  List<FanPageModel> _discoverPages = [];
  bool _isLoadingDiscover = true;

  // My pages state
  List<FanPageModel> _managedPages = [];
  List<FanPageModel> _followedPages = [];
  bool _isLoadingMy = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _fetchCategories();
    _fetchDiscoverPages();
    _fetchMyPages();
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await _service.getCategories();
      if (mounted) {
        setState(() => _categories = cats);
      }
    } catch (_) {}
  }

  Future<void> _fetchDiscoverPages() async {
    setState(() => _isLoadingDiscover = true);
    try {
      final pages = await _service.getPages(
        query: _searchController.text.trim(),
        category: _selectedCategorySlug,
      );
      if (mounted) {
        setState(() {
          _discoverPages = pages;
          _isLoadingDiscover = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingDiscover = false);
      }
    }
  }

  Future<void> _fetchMyPages() async {
    setState(() => _isLoadingMy = true);
    try {
      final my = await _service.getMyPages();
      if (mounted) {
        setState(() {
          _managedPages = my['managed'] ?? [];
          _followedPages = my['followed'] ?? [];
          _isLoadingMy = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMy = false);
      }
    }
  }

  void _updatePageInLists(FanPageModel updated) {
    setState(() {
      final dIdx = _discoverPages.indexWhere((p) => p.id == updated.id);
      if (dIdx != -1) _discoverPages[dIdx] = updated;

      final mIdx = _managedPages.indexWhere((p) => p.id == updated.id);
      if (mIdx != -1) _managedPages[mIdx] = updated;

      final fIdx = _followedPages.indexWhere((p) => p.id == updated.id);
      if (updated.isFollowing) {
        if (fIdx == -1) {
          _followedPages.add(updated);
        } else {
          _followedPages[fIdx] = updated;
        }
      } else {
        if (fIdx != -1) {
          _followedPages.removeAt(fIdx);
        }
      }
    });
  }

  Future<void> _toggleFollow(FanPageModel page) async {
    final newFollow = !page.isFollowing;
    final newCount = page.followersCount + (newFollow ? 1 : -1);
    final optimistic = page.copyWith(isFollowing: newFollow, followersCount: newCount < 0 ? 0 : newCount);
    _updatePageInLists(optimistic);

    try {
      final res = await _service.toggleFollow(page.slug);
      final serverFollow = res['is_followed'] as bool? ?? newFollow;
      final serverCount = res['followers'] as int? ?? newCount;
      final verified = page.copyWith(isFollowing: serverFollow, followersCount: serverCount);
      _updatePageInLists(verified);
    } catch (_) {
      if (mounted) {
        _updatePageInLists(page);
        Get.snackbar('Error', 'Failed to update follow status');
      }
    }
  }

  void _showCreatePageSheet() {
    final nameCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
    final websiteCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    int? selectedCatId = _categories.isNotEmpty ? _categories.first.id : null;
    File? avatarFile;
    File? coverFile;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create Fan Page',
                      style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Connect with customers, fans, and your community',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // Avatar & Cover Pickers
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final img = await picker.pickImage(source: ImageSource.gallery);
                            if (img != null) {
                              setSheetState(() => avatarFile = File(img.path));
                            }
                          },
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: avatarFile != null ? FileImage(avatarFile!) : null,
                            child: avatarFile == null
                                ? HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: AppColors.primary, size: 24)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final img = await picker.pickImage(source: ImageSource.gallery);
                              if (img != null) {
                                setSheetState(() => coverFile = File(img.path));
                              }
                            },
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                image: coverFile != null
                                    ? DecorationImage(image: FileImage(coverFile!), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: coverFile == null
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: AppColors.primary, size: 18),
                                        const SizedBox(width: 8),
                                        Text('Upload Cover', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Page Name
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Page Name *',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: HugeIcon(icon: HugeIcons.strokeRoundedFlag02, size: 20, color: AppColors.textSecondary),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category
                    if (_categories.isNotEmpty)
                      DropdownButtonFormField<int>(
                        initialValue: selectedCatId,
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: HugeIcon(icon: HugeIcons.strokeRoundedFolder01, size: 20, color: AppColors.textSecondary),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _categories.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (val) => setSheetState(() => selectedCatId = val),
                      ),
                    const SizedBox(height: 12),

                    // Bio
                    TextField(
                      controller: bioCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Bio / Description',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: HugeIcon(icon: HugeIcons.strokeRoundedEdit02, size: 20, color: AppColors.textSecondary),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Website & Location
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: websiteCtrl,
                            decoration: InputDecoration(
                              labelText: 'Website',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: locationCtrl,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                if (name.isEmpty) {
                                  Get.snackbar('Required', 'Please enter a page name');
                                  return;
                                }
                                if (selectedCatId == null) {
                                  Get.snackbar('Required', 'Please select a category');
                                  return;
                                }

                                setSheetState(() => isSubmitting = true);
                                try {
                                  final newPage = await _service.createPage(
                                    name: name,
                                    categoryId: selectedCatId!,
                                    bio: bioCtrl.text.trim().isNotEmpty ? bioCtrl.text.trim() : null,
                                    website: websiteCtrl.text.trim().isNotEmpty ? websiteCtrl.text.trim() : null,
                                    location: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : null,
                                    avatarFile: avatarFile,
                                    coverFile: coverFile,
                                  );

                                  if (mounted) {
                                    Get.back();
                                    _fetchMyPages();
                                    _fetchDiscoverPages();
                                    Get.to(() => FanPageProfilePage(slug: newPage.slug, initialPage: newPage));
                                    Get.snackbar('Success', 'Page created successfully!', backgroundColor: Colors.green, colorText: Colors.white);
                                  }
                                } catch (e) {
                                  setSheetState(() => isSubmitting = false);
                                  Get.snackbar('Error', 'Failed to create page: $e');
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Create Page', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Pages & Businesses', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        actions: [
          IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedPlusSignCircle, color: AppColors.primary, size: 24),
            tooltip: 'Create Page',
            onPressed: _showCreatePageSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Discover'),
            Tab(text: 'My Pages'),
            Tab(text: 'Liked Pages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTab(),
          _buildMyPagesTab(),
          _buildFollowedPagesTab(),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return RefreshIndicator(
      onRefresh: _fetchDiscoverPages,
      child: Column(
        children: [
          // Search & Filter header
          Container(
            color: AppColors.cardBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search fan pages and businesses...',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 20, color: AppColors.textSecondary),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchDiscoverPages();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _fetchDiscoverPages(),
                ),
                if (_categories.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length + 1,
                      separatorBuilder: (_, unused) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isSelected = _selectedCategorySlug == null;
                          return ChoiceChip(
                            label: const Text('All Categories'),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              setState(() => _selectedCategorySlug = null);
                              _fetchDiscoverPages();
                            },
                          );
                        }
                        final cat = _categories[index - 1];
                        final isSelected = _selectedCategorySlug == cat.slug;
                        return ChoiceChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedCategorySlug = isSelected ? null : cat.slug);
                            _fetchDiscoverPages();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Pages List
          Expanded(
            child: _isLoadingDiscover
                ? const Center(child: CircularProgressIndicator())
                : _discoverPages.isEmpty
                    ? _buildEmptyState(
                        title: 'No Pages Found',
                        message: 'Try adjusting your search or explore other categories.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _discoverPages.length,
                        itemBuilder: (context, index) {
                          return _buildPageCard(_discoverPages[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPagesTab() {
    return RefreshIndicator(
      onRefresh: _fetchMyPages,
      child: _isLoadingMy
          ? const Center(child: CircularProgressIndicator())
          : _managedPages.isEmpty
              ? _buildEmptyState(
                  title: 'No Pages Managed',
                  message: 'You haven\'t created or joined any fan pages yet. Create one today!',
                  actionLabel: 'Create a Page',
                  onAction: _showCreatePageSheet,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _managedPages.length,
                  itemBuilder: (context, index) {
                    return _buildPageCard(_managedPages[index], isManaged: true);
                  },
                ),
    );
  }

  Widget _buildFollowedPagesTab() {
    return RefreshIndicator(
      onRefresh: _fetchMyPages,
      child: _isLoadingMy
          ? const Center(child: CircularProgressIndicator())
          : _followedPages.isEmpty
              ? _buildEmptyState(
                  title: 'No Liked Pages',
                  message: 'Explore and follow fan pages to see their latest updates in your feed.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _followedPages.length,
                  itemBuilder: (context, index) {
                    return _buildPageCard(_followedPages[index]);
                  },
                ),
    );
  }

  Widget _buildPageCard(FanPageModel page, {bool isManaged = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Get.to(() => FanPageProfilePage(slug: page.slug, initialPage: page));
          _fetchDiscoverPages();
          _fetchMyPages();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Photo Header
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: CustomNetworkImage(
                      imageUrl: page.coverPhoto,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Avatar positioned over bottom edge
                Positioned(
                  left: 16,
                  bottom: -24,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardBg, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CustomNetworkImage(
                        imageUrl: page.avatar,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: Colors.grey.shade200,
                          child: HugeIcon(icon: HugeIcons.strokeRoundedFlag02, color: AppColors.primary, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
                // Category badge top right
                if (page.categoryName != null)
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        page.categoryName!,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 32),

            // Details and actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                page.name,
                                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (page.isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.verified, size: 16, color: AppColors.primary),
                            ],
                          ],
                        ),
                      ),
                      if (isManaged || page.canManage)
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await Get.to(() => FanPageManagePage(page: page));
                            _fetchDiscoverPages();
                            _fetchMyPages();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.settings, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  page.userRole?.toUpperCase() ?? 'MANAGE',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 34,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: page.isFollowing
                                  ? AppColors.textSecondary.withValues(alpha: 0.12)
                                  : AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onPressed: () => _toggleFollow(page),
                            child: Text(
                              page.isFollowing ? 'Following' : '+ Follow',
                              style: TextStyle(
                                color: page.isFollowing ? AppColors.textMain : Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (page.bio != null && page.bio!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      page.bio!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedUserMultiple02, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${page.followersCount} followers',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      if (page.rating > 0) ...[
                        const SizedBox(width: 14),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          page.rating.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                  if (isManaged) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: OutlinedButton.icon(
                              onPressed: () => Get.to(() => FanPageInboxPage(page: page)),
                              icon: const Icon(Icons.mail_outline, size: 16),
                              label: const Text('Inbox', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await Get.to(() => FanPageManagePage(page: page));
                                _fetchMyPages();
                              },
                              icon: const Icon(Icons.settings_outlined, size: 16),
                              label: const Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedFlag02,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: Text(actionLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
