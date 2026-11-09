import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/chat_controller.dart';
import '../../data/services/chat_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_avatar.dart';
import '../../widgets/common/professional_badge.dart';

class RoomInfoSheet extends StatefulWidget {
  final int roomId;
  final ChatController chatController;

  const RoomInfoSheet({
    super.key,
    required this.roomId,
    required this.chatController,
  });

  static void show(
    BuildContext context, {
    required int roomId,
    required ChatController chatController,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          RoomInfoSheet(roomId: roomId, chatController: chatController),
    );
  }

  @override
  State<RoomInfoSheet> createState() => _RoomInfoSheetState();
}

class _RoomInfoSheetState extends State<RoomInfoSheet> {
  final ChatService _service = ChatService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  Map<String, dynamic> _room = {};
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _searchResults = [];
  final Set<int> _selectedIds = {};

  String? get _myRole {
    final fromRoom = _room['my_role']?.toString();
    if (fromRoom != null && fromRoom.isNotEmpty) return fromRoom;
    final fromCtrl = widget.chatController.activeMyRole;
    if (fromCtrl != null && fromCtrl.isNotEmpty) return fromCtrl;
    final myId = widget.chatController.currentUserId;
    if (myId == 0) return null;
    for (final m in _members) {
      if (m['user_id'] == myId) return m['role']?.toString();
    }
    return null;
  }

  bool get _canManage {
    final role = _myRole;
    return role == 'owner' || role == 'admin';
  }

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getRoomInfo(widget.roomId);
      _room = data['room'] as Map<String, dynamic>? ?? {};
      _members = data['members'] as List<Map<String, dynamic>>? ?? [];
    } catch (e) {
      debugPrint('Room info error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onSearch() async {
    final q = _searchController.text.trim();
    if (q.length < 1) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final users = await _service.searchUsers(q);
      setState(() => _searchResults = users);
    } catch (_) {}
  }

  Future<void> _pickAvatar() async {
    if (!_canManage) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    try {
      await _service.updateRoomAvatar(widget.roomId, File(file.path));
      await _load();
      await widget.chatController.loadConversations(showLoading: false);
      Get.snackbar('success'.tr, 'group_avatar_updated'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_update_avatar'.tr);
    }
  }

  Future<void> _addSelected() async {
    if (_selectedIds.isEmpty) return;
    try {
      await _service.addRoomMembers(widget.roomId, _selectedIds.toList());
      _selectedIds.clear();
      _searchController.clear();
      await _load();
      Get.snackbar('success'.tr, 'members_added'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_add_members'.tr);
    }
  }

  Future<void> _leave() async {
    try {
      await _service.leaveRoom(widget.roomId);
      Get.back();
      Get.back();
      widget.chatController.leaveConversation();
      await widget.chatController.loadConversations(showLoading: false);
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_leave_group'.tr);
    }
  }

  Widget _roleBadge(String? role) {
    if (role == 'owner') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF1877F2).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'admin'.tr,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1877F2),
          ),
        ),
      );
    }
    if (role == 'admin') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'admin'.tr,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );
    }
    if (role == 'subscriber') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'subscriber'.tr,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final title = _room['title']?.toString() ?? '';
    final avatar = _room['avatar']?.toString();
    final description = _room['description']?.toString();
    final isChannel =
        (_room['type'] ?? widget.chatController.activeRoomType) == 'channel';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isChannel ? 'channel_info'.tr : 'group_info'.tr,
                      style: AppTextStyles.h3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _canManage ? _pickAvatar : null,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CustomAvatar(
                            avatarUrl: avatar,
                            name: title,
                            radius: 40,
                          ),
                          if (_canManage)
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primary,
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: AppTextStyles.h3,
                      textAlign: TextAlign.center,
                    ),
                    if (description != null && description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          description,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text('members'.tr, style: AppTextStyles.h4),
                    const SizedBox(height: 8),
                    ..._members.map((m) {
                      final pt = m['profile_type']?.toString();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CustomAvatar(
                          avatarUrl: m['avatar']?.toString(),
                          name: m['name']?.toString() ?? '',
                          radius: 22,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                m['name']?.toString() ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (pt != null && pt != 'user') ...[
                              const SizedBox(width: 4),
                              ProfessionalBadge(profileType: pt, size: 14),
                            ],
                          ],
                        ),
                        trailing: _roleBadge(m['role']?.toString()),
                      );
                    }),
                    if (_canManage) ...[
                      const SizedBox(height: 16),
                      Text('add_members'.tr, style: AppTextStyles.h4),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'search_friends'.tr,
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      ..._searchResults.map((u) {
                        final id = u['id'] as int;
                        final selected = _selectedIds.contains(id);
                        return ListTile(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedIds.remove(id);
                              } else {
                                _selectedIds.add(id);
                              }
                            });
                          },
                          leading: CustomAvatar(
                            avatarUrl: u['avatar']?.toString(),
                            name: u['name']?.toString() ?? '',
                            radius: 20,
                          ),
                          title: Text(u['name']?.toString() ?? ''),
                          trailing: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: AppColors.primary,
                          ),
                        );
                      }),
                      if (_selectedIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ElevatedButton(
                            onPressed: _addSelected,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('add_members'.tr),
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: _leave,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('leave_group'.tr),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
