import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';
import '../../data/models/conversation_model.dart';
import '../../data/services/chat_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_avatar.dart';

class CreateRoomSheet extends StatefulWidget {
  final String type;
  final ChatController chatController;

  const CreateRoomSheet({
    super.key,
    required this.type,
    required this.chatController,
  });

  @override
  State<CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<CreateRoomSheet> {
  final ChatService _service = ChatService();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _search = TextEditingController();
  final Map<int, Map<String, dynamic>> _selectedUsers = {};
  List<Map<String, dynamic>> _users = [];
  bool _loadingUsers = false;
  bool _isPublic = false;
  bool _saving = false;
  Timer? _debounceTimer;

  bool get _isChannel => widget.type == 'channel';

  @override
  void initState() {
    super.initState();
    _loadUsers('');
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _title.dispose();
    _description.dispose();
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadUsers(_search.text.trim());
    });
  }

  Future<void> _loadUsers(String query) async {
    if (!mounted) return;
    setState(() => _loadingUsers = true);
    try {
      final results = await _service.searchUsers(query);
      if (!mounted) return;
      setState(() {
        _users = results;
        _loadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      Get.snackbar('error'.tr, 'name_is_required'.tr);
      return;
    }
    setState(() => _saving = true);
    try {
      final data = await _service.createRoom(
        type: widget.type,
        title: title,
        description: _description.text.trim(),
        memberIds: _selectedUsers.keys.toList(),
        isPublic: _isPublic,
      );
      final room = data['room'];
      if (room is! Map) throw Exception('Missing room');
      if (!mounted) return;
      Navigator.of(context).pop(Map<String, dynamic>.from(room));
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text(
                _isChannel ? 'new_channel'.tr : 'new_group'.tr,
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: 'name'.tr,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'description'.tr,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_isChannel) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('make_public'.tr),
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('add_members'.tr, style: AppTextStyles.h4),
                  if (_selectedUsers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_selectedUsers.length} selected',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              if (_selectedUsers.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _selectedUsers.entries.map((entry) {
                      final u = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: CustomAvatar(
                            avatarUrl: u['avatar']?.toString(),
                            name: u['name']?.toString() ?? '',
                            radius: 12,
                          ),
                          label: Text(
                            u['name']?.toString() ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _selectedUsers.remove(entry.key);
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'search_friends'.tr,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _search.clear();
                            _loadUsers('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              if (_loadingUsers)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_users.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'no_users_found'.tr,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ..._users.map((user) {
                  final id = int.tryParse('${user['id']}') ?? 0;
                  final selected = _selectedUsers.containsKey(id);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CustomAvatar(
                      avatarUrl: user['avatar']?.toString(),
                      name: user['name']?.toString() ?? '',
                      radius: 20,
                    ),
                    title: Text(
                      user['name']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: user['username'] != null
                        ? Text('@${user['username']}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
                        : null,
                    trailing: Icon(
                      selected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedUsers.remove(id);
                        } else {
                          _selectedUsers[id] = user;
                        }
                      });
                    },
                  );
                }),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('create'.tr),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PublicChannelsSheet extends StatefulWidget {
  const PublicChannelsSheet({super.key});

  @override
  State<PublicChannelsSheet> createState() => _PublicChannelsSheetState();
}

class _PublicChannelsSheetState extends State<PublicChannelsSheet> {
  final ChatService _service = ChatService();
  bool _loading = true;
  List<Map<String, dynamic>> _channels = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.publicChannels();
      if (mounted) setState(() => _channels = items);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join(int id) async {
    try {
      final data = await _service.joinChannel(id);
      final room = data['room'];
      if (room is! Map || !mounted) return;
      Navigator.of(context).pop(Map<String, dynamic>.from(room));
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Text('public_channels'.tr, style: AppTextStyles.h3, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    if (_channels.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('no_public_channels'.tr, textAlign: TextAlign.center),
                      )
                    else
                      ..._channels.map((c) {
                        final id = int.tryParse('${c['id']}') ?? 0;
                        return ListTile(
                          leading: CustomAvatar(
                            avatarUrl: c['avatar']?.toString(),
                            name: c['title']?.toString() ?? '',
                            radius: 20,
                          ),
                          title: Text(c['title']?.toString() ?? ''),
                          subtitle: Text('${c['member_count'] ?? 0}'),
                          trailing: TextButton(
                            onPressed: () => _join(id),
                            child: Text('join'.tr),
                          ),
                        );
                      }),
                  ],
                ),
        );
      },
    );
  }
}

ConversationModel conversationFromRoom(Map<String, dynamic> room) {
  final title = room['title']?.toString() ?? 'Room';
  final avatar = room['avatar']?.toString();
  return ConversationModel(
    id: int.tryParse('${room['id']}') ?? 0,
    kind: 'room',
    roomType: room['type']?.toString() ?? room['room_type']?.toString(),
    roomTitle: title,
    roomAvatar: avatar,
    canPost: room['can_post'] != false,
    myRole: room['my_role']?.toString(),
    user: ChatUser(
      id: 0,
      name: title,
      avatar: (avatar != null && avatar.isNotEmpty)
          ? avatar
          : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(title)}&background=random',
    ),
    unreadCount: 0,
    settings: {},
  );
}
