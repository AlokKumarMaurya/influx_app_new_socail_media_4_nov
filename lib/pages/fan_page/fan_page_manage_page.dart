import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/fan_page_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/fan_page_service.dart';
import '../../data/services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_network_image.dart';

class FanPageManagePage extends StatefulWidget {
  final FanPageModel page;

  const FanPageManagePage({super.key, required this.page});

  @override
  State<FanPageManagePage> createState() => _FanPageManagePageState();
}

class _FanPageManagePageState extends State<FanPageManagePage> with SingleTickerProviderStateMixin {
  final FanPageService _service = FanPageService();
  final PostService _postService = PostService();
  late TabController _tabController;

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _descController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _ctaUrlController;

  int? _selectedCategoryId;
  String _ctaType = 'message';
  bool _allowVisitorPosts = true;
  bool _isSaving = false;
  List<FanPageCategoryModel> _categories = [];

  String? _avatarUrl;
  String? _coverUrl;

  List<dynamic> _members = [];
  Map<String, dynamic>? _owner;
  bool _isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _nameController = TextEditingController(text: widget.page.name);
    _bioController = TextEditingController(text: widget.page.bio ?? '');
    _descController = TextEditingController(text: widget.page.description ?? '');
    _locationController = TextEditingController(text: widget.page.location ?? '');
    _websiteController = TextEditingController(text: widget.page.website ?? '');
    _phoneController = TextEditingController(text: widget.page.phone ?? '');
    _emailController = TextEditingController(text: widget.page.email ?? '');
    _ctaUrlController = TextEditingController(text: widget.page.ctaButtonUrl ?? '');

    _selectedCategoryId = widget.page.categoryId;
    _ctaType = widget.page.ctaButtonType;
    _allowVisitorPosts = widget.page.allowVisitorPosts;
    _avatarUrl = widget.page.avatar;
    _coverUrl = widget.page.coverPhoto;

    _loadCategories();
    _loadMembers();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await _service.getCategories();
      if (mounted) setState(() => _categories = list);
    } catch (_) {}
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    try {
      final res = await _service.getPageMembers(widget.page.slug);
      if (mounted) {
        setState(() {
          _owner = res['owner'] is Map<String, dynamic> ? res['owner'] : null;
          _members = (res['members'] as List?) ?? [];
          _isLoadingMembers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      try {
        final newUrl = await _service.updateAvatar(widget.page.slug, File(picked.path));
        Get.back();
        setState(() => _avatarUrl = newUrl);
        Get.snackbar('Success', 'Avatar updated successfully', backgroundColor: Colors.green, colorText: Colors.white);
      } catch (e) {
        Get.back();
        Get.snackbar('Error', 'Failed to update avatar', backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<void> _pickAndUploadCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      try {
        final newUrl = await _service.updateCover(widget.page.slug, File(picked.path));
        Get.back();
        setState(() => _coverUrl = newUrl);
        Get.snackbar('Success', 'Cover photo updated successfully', backgroundColor: Colors.green, colorText: Colors.white);
      } catch (e) {
        Get.back();
        Get.snackbar('Error', 'Failed to update cover', backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_nameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Page name is required', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'name': _nameController.text.trim(),
        'category_id': _selectedCategoryId,
        'bio': _bioController.text.trim(),
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'cta_button_type': _ctaType,
        'cta_button_url': _ctaUrlController.text.trim(),
        'allow_visitor_posts': _allowVisitorPosts ? 1 : 0,
      };

      await _service.updatePage(widget.page.slug, payload);
      Get.snackbar('Success', 'Page settings saved successfully', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save page settings', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddMemberDialog() {
    UserModel? selectedUser;
    String selectedRole = 'editor';
    List<UserModel> searchResults = [];
    bool isSearching = false;
    final searchController = TextEditingController();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Material(
            color: Colors.transparent,
            child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Team Member',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (selectedUser == null) ...[
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search user by name or @username...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) async {
                        final q = val.trim();
                        if (q.isEmpty) {
                          setSheetState(() => searchResults = []);
                          return;
                        }
                        setSheetState(() => isSearching = true);
                        try {
                          final results = await _postService.searchUsers(q, friendsOnly: false);
                          setSheetState(() {
                            searchResults = results;
                            isSearching = false;
                          });
                        } catch (_) {
                          setSheetState(() => isSearching = false);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (searchResults.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final u = searchResults[i];
                            return ListTile(
                              dense: true,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: CustomNetworkImage(
                                  imageUrl: u.avatar,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(
                                u.username != null ? '@${u.username}' : '',
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                              trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
                              onTap: () {
                                setSheetState(() {
                                  selectedUser = u;
                                  searchResults = [];
                                });
                              },
                            );
                          },
                        ),
                      )
                    else if (searchController.text.trim().isNotEmpty && !isSearching)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text('No users found with that name or username', style: TextStyle(color: Colors.black54, fontSize: 13)),
                        ),
                      ),
                  ] else ...[
                    // Selected user card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CustomNetworkImage(
                              imageUrl: selectedUser!.avatar,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selectedUser!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                if (selectedUser!.username != null)
                                  Text('@${selectedUser!.username}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() => selectedUser = null);
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Role Permission',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin (Full access)')),
                      DropdownMenuItem(value: 'editor', child: Text('Editor (Post & Reply)')),
                      DropdownMenuItem(value: 'moderator', child: Text('Moderator (Reply & Review)')),
                      DropdownMenuItem(value: 'advertiser', child: Text('Advertiser (Ads & Campaigns)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: selectedUser == null
                          ? null
                          : () async {
                              Get.back();
                              try {
                                await _service.assignMember(
                                  widget.page.slug,
                                  userId: selectedUser!.id,
                                  role: selectedRole,
                                );
                                _loadMembers();
                                Get.snackbar(
                                  'Success',
                                  '${selectedUser!.name} assigned as $selectedRole',
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                );
                              } catch (e) {
                                Get.snackbar('Error', 'Failed to assign team member', backgroundColor: Colors.red, colorText: Colors.white);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Assign to Page Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  void _confirmRemoveMember(int userId, String name) {
    Get.defaultDialog(
      title: 'Remove Team Member',
      middleText: 'Are you sure you want to remove $name from the page team?',
      textConfirm: 'Remove',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        try {
          await _service.removeMember(widget.page.slug, userId);
          _loadMembers();
          Get.snackbar('Success', '$name removed from page team', backgroundColor: Colors.green, colorText: Colors.white);
        } catch (e) {
          Get.snackbar('Error', 'Failed to remove team member', backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );
  }

  void _confirmDeletePage() {
    Get.defaultDialog(
      title: 'Delete Page',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      middleText: 'Are you sure you want to delete ${widget.page.name}? This action cannot be undone.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
        try {
          await _service.deletePage(widget.page.slug);
          Get.back(); // close loader
          Get.back(); // close manage page
          Get.back(); // close profile page
          Get.snackbar('Deleted', 'Page has been removed', backgroundColor: Colors.black87, colorText: Colors.white);
        } catch (e) {
          Get.back();
          Get.snackbar('Error', 'Failed to delete page', backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ctaUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Manage Page', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'General & Media'),
            Tab(text: 'Team & Roles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildTeamTab(),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover & Avatar Media Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      color: AppColors.primary.withValues(alpha: 0.2),
                      child: CustomNetworkImage(
                        imageUrl: _coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(color: AppColors.primary),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          onPressed: _pickAndUploadCover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -28,
                      left: 16,
                      child: Stack(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: ClipOval(
                              child: CustomNetworkImage(
                                imageUrl: _avatarUrl,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.flag, size: 28, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.primary,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit, size: 12, color: Colors.white),
                                onPressed: _pickAndUploadAvatar,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 38),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(widget.page.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.image, size: 16),
                        label: const Text('Change Cover'),
                        onPressed: _pickAndUploadCover,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details Form
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Page Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Page Name *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bioController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Short Bio', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Full Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location / Address', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _websiteController,
                    decoration: const InputDecoration(labelText: 'Website', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  const Text('Call to Action (CTA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _ctaType,
                    decoration: const InputDecoration(labelText: 'Button Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('None')),
                      DropdownMenuItem(value: 'message', child: Text('Send Message')),
                      DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                      DropdownMenuItem(value: 'call', child: Text('Call Now')),
                      DropdownMenuItem(value: 'website', child: Text('Visit Website')),
                      DropdownMenuItem(value: 'shop', child: Text('Shop Now')),
                      DropdownMenuItem(value: 'email', child: Text('Send Email')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _ctaType = val);
                    },
                  ),
                  if (_ctaType != 'none' && _ctaType != 'message') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ctaUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Action URL / Phone / Email',
                        border: OutlineInputBorder(),
                        hintText: 'https://... or phone number',
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Allow Visitor Posts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Visitors can publish posts directly on your page timeline', style: TextStyle(fontSize: 12)),
                    value: _allowVisitorPosts,
                    onChanged: (val) => setState(() => _allowVisitorPosts = val),
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Danger Zone
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Danger Zone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
                  const SizedBox(height: 4),
                  const Text('Permanently delete this page and all its posts, photos, and messages.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _confirmDeletePage,
                    icon: const Icon(Icons.delete_forever, color: Colors.red, size: 18),
                    label: const Text('Delete Page', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Page Roles & Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ElevatedButton.icon(
                      onPressed: _showAddMemberDialog,
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Staff'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage administrators, editors, and moderators who can reply to messages and publish posts.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text('Current Page Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),

        // Page Owner Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomNetworkImage(
                imageUrl: _owner?['avatar_url']?.toString() ?? _owner?['avatar']?.toString(),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              _owner?['name']?.toString() ?? 'Page Owner',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text('Page Owner', style: TextStyle(fontSize: 12, color: Colors.black54)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Owner',
                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
        ),

        if (_isLoadingMembers)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_members.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.group_outlined, size: 40, color: Colors.black26),
                  SizedBox(height: 8),
                  Text('No additional team members yet', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('Tap "Add Staff" to invite editors or moderators.', style: TextStyle(color: Colors.black38, fontSize: 11)),
                ],
              ),
            ),
          )
        else
          ..._members.map((m) {
            final user = m['user'] is Map<String, dynamic> ? m['user'] : {};
            final role = m['role']?.toString() ?? 'editor';
            final userId = m['user_id'] is int ? m['user_id'] : int.tryParse(m['user_id']?.toString() ?? '0') ?? 0;
            final userName = user['name']?.toString() ?? 'Member';
            final userAvatar = user['avatar_url']?.toString() ?? user['avatar']?.toString();

            return Card(
              margin: const EdgeInsets.only(top: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomNetworkImage(
                    imageUrl: userAvatar,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  role.toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                  onPressed: () => _confirmRemoveMember(userId, userName),
                  tooltip: 'Remove Role',
                ),
              ),
            );
          }),
        const SizedBox(height: 32),
      ],
    );
  }
}
