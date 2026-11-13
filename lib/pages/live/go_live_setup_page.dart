import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/live_stream_controller.dart';
import 'live_room_page.dart';

class GoLiveSetupPage extends StatefulWidget {
  final int? initialFanPageId;
  final String? initialFanPageName;

  const GoLiveSetupPage({
    super.key,
    this.initialFanPageId,
    this.initialFanPageName,
  });

  @override
  State<GoLiveSetupPage> createState() => _GoLiveSetupPageState();
}

class _GoLiveSetupPageState extends State<GoLiveSetupPage> {
  final LiveStreamController _liveCtrl =
      Get.isRegistered<LiveStreamController>()
      ? Get.find<LiveStreamController>()
      : Get.put(LiveStreamController());

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _feeCtrl = TextEditingController(text: '5.00');

  String _selectedCategory = 'general';
  int? _selectedFanPageId;
  String? _selectedIdentityName;
  String? _selectedIdentityAvatar;
  String _selectedIdentityBadge = 'Personal Profile';

  bool _isPaid = false;
  bool _allowComments = true;
  bool _allowGifts = true;
  bool _allowTips = true;
  bool _isStarting = false;
  File? _thumbnailFile;

  final List<Map<String, dynamic>> _categories = [
    {'key': 'general', 'label': 'Just Chatting', 'icon': HugeIcons.strokeRoundedComment01},
    {'key': 'gaming', 'label': 'Gaming', 'icon': HugeIcons.strokeRoundedVideo02},
    {'key': 'music', 'label': 'Music & Concert', 'icon': HugeIcons.strokeRoundedAward01},
    {'key': 'education', 'label': 'Education & Tech', 'icon': HugeIcons.strokeRoundedChartHistogram},
    {'key': 'shopping', 'label': 'Live Shopping', 'icon': HugeIcons.strokeRoundedWallet01},
    {'key': 'popular', 'label': 'Trending', 'icon': HugeIcons.strokeRoundedFavourite},
  ];

  @override
  void initState() {
    super.initState();
    final user = Get.find<AuthController>().user.value;
    _selectedFanPageId = widget.initialFanPageId;
    if (widget.initialFanPageId != null) {
      _selectedIdentityName = widget.initialFanPageName ?? 'Fan Page';
      _selectedIdentityBadge = 'Official Fan Page';
    } else {
      _selectedIdentityName = user?.name ?? 'Creator';
      _selectedIdentityAvatar = user?.avatar;
      _selectedIdentityBadge = 'Personal Profile';
    }
    _titleCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _feeCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _liveCtrl.loadLiveConfig();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _thumbnailFile = File(picked.path));
    }
  }

  Future<void> _startBroadcast() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      Get.snackbar(
        'Title Required',
        'Please enter a title for your live broadcast.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isStarting = true);
    final stream = await _liveCtrl.startNewBroadcast(
      title: title,
      description: _descCtrl.text.trim(),
      category: _selectedCategory,
      fanPageId: _selectedFanPageId,
      isPaid: _isPaid,
      entryFee: double.tryParse(_feeCtrl.text) ?? 5.0,
      thumbnailFile: _thumbnailFile,
    );
    if (mounted) {
      setState(() => _isStarting = false);
    }

    if (stream != null) {
      Get.off(() => LiveRoomPage(uuid: stream.uuid));
    }
  }

  String get _currentCategoryLabel {
    final match = _categories.firstWhere(
      (c) => c['key'] == _selectedCategory,
      orElse: () => _categories.first,
    );
    return (match['label'] ?? 'General').toString();
  }

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthController>().user.value;
    final entryFeeVal = double.tryParse(_feeCtrl.text) ?? 0.0;
    final hostNetEarning = (entryFeeVal * 0.90).clamp(0.0, 999999.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF2D55),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Creator Live Studio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Studio Hero & Real-Time Feed/Discovery Card Preview
            _buildLivePreviewStage(user, entryFeeVal),
            const SizedBox(height: 18),

            // STEP 1: Broadcast Identity Card Selector
            _buildStepCard(
              step: '1',
              title: 'Broadcast Identity',
              subtitle:
                  'Choose whether to stream from your personal profile or a Fan Page',
              child: Obx(() {
                final pages = _liveCtrl.managedPages;
                return Column(
                  children: [
                    _buildIdentityOptionCard(
                      id: null,
                      name: user?.name ?? 'Personal Profile',
                      avatarUrl: user?.avatar ?? '',
                      badgeText: 'Personal Profile',
                      badgeColor: const Color(0xFF8B5CF6),
                      isSelected: _selectedFanPageId == null,
                    ),
                    ...pages.map((p) {
                      final pageId = (p['id'] as num).toInt();
                      final pageName = (p['name'] ?? 'Fan Page').toString();
                      final pageAvatar = (p['avatar_url'] ?? '').toString();
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _buildIdentityOptionCard(
                          id: pageId,
                          name: pageName,
                          avatarUrl: pageAvatar,
                          badgeText: 'Official Fan Page',
                          badgeColor: const Color(0xFF0EA5E9),
                          isSelected: _selectedFanPageId == pageId,
                        ),
                      );
                    }),
                    if (widget.initialFanPageId != null &&
                        !pages.any(
                          (p) =>
                              (p['id'] as num).toInt() ==
                              widget.initialFanPageId,
                        ))
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _buildIdentityOptionCard(
                          id: widget.initialFanPageId,
                          name: widget.initialFanPageName ?? 'Fan Page',
                          avatarUrl: '',
                          badgeText: 'Official Fan Page',
                          badgeColor: const Color(0xFF0EA5E9),
                          isSelected:
                              _selectedFanPageId == widget.initialFanPageId,
                        ),
                      ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),

            // STEP 2: Stream Title, Category Pills & Description
            _buildStepCard(
              step: '2',
              title: 'Stream Details & Category',
              subtitle:
                  'Give your broadcast a catchy title for the Story Slider & Home Feed',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Stream Title *',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${_titleCtrl.text.length} / 160',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleCtrl,
                    maxLength: 160,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText:
                          'e.g. Late Night Q&A, Ranked Match, Live Product Drop...',
                      hintStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B5CF6),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Category',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final active = _selectedCategory == cat['key'];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cat['key']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            gradient: active
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFFEC4899),
                                    ],
                                  )
                                : null,
                            color: active ? null : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: active
                                  ? Colors.transparent
                                  : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF8B5CF6,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: cat['icon'],
                                size: 15,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF8B5CF6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat['label'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Stream Description (Optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Add notes, schedule info, or topics you will cover...',
                      hintStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // STEP 3: Custom Cover Thumbnail Dropzone
            _buildStepCard(
              step: '3',
              title: 'Cover Thumbnail (Optional)',
              subtitle:
                  'Displayed on the Live Hub grid, Home Feed post, and suggestions',
              trailing: _thumbnailFile != null
                  ? TextButton.icon(
                      onPressed: () => setState(() => _thumbnailFile = null),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 15,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        'Remove',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    )
                  : null,
              child: GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    image: _thumbnailFile != null
                        ? DecorationImage(
                            image: FileImage(_thumbnailFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _thumbnailFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedCamera01,
                                  size: 24,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to upload custom stream cover',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'PNG, JPG or WEBP (Defaults to your profile/page cover)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Tap to change cover',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // STEP 4: Room Interactions & VIP Paid Live Ticket
            _buildStepCard(
              step: '4',
              title: 'Room Interactions & Monetization',
              subtitle:
                  'Control live chat, animated gifts, wallet tips, and VIP ticketed entry',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureMiniToggle(
                          label: 'Chat',
                          hugeIcon: HugeIcons.strokeRoundedComment01,
                          value: _allowComments,
                          onChanged: (v) => setState(() => _allowComments = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFeatureMiniToggle(
                          label: 'Gifts',
                          hugeIcon: HugeIcons.strokeRoundedAward01,
                          value: _allowGifts,
                          onChanged: (v) => setState(() => _allowGifts = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFeatureMiniToggle(
                          label: 'Tips',
                          hugeIcon: HugeIcons.strokeRoundedWallet01,
                          value: _allowTips,
                          onChanged: (v) => setState(() => _allowTips = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF59E0B).withValues(alpha: 0.08),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedLock,
                                color: Color(0xFFD97706),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'VIP / Paid Ticketed Live Stream',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    'Require viewers to purchase an entry ticket from their wallet',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPaid,
                              activeThumbColor: const Color(0xFF8B5CF6),
                              onChanged: (v) => setState(() => _isPaid = v),
                            ),
                          ],
                        ),
                        if (_isPaid) ...[
                          const Divider(height: 22),
                          const Text(
                            'Quick Ticket Price Presets',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [5, 10, 20, 50].map((preset) {
                              final isPreset =
                                  (double.tryParse(_feeCtrl.text) ?? 0) ==
                                  preset.toDouble();
                              return GestureDetector(
                                onTap: () => setState(
                                  () =>
                                      _feeCtrl.text = preset.toStringAsFixed(2),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPreset
                                        ? const Color(0xFF8B5CF6)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isPreset
                                          ? const Color(0xFF8B5CF6)
                                          : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Text(
                                    '${_liveCtrl.currencySymbol.value}$preset',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isPreset
                                          ? Colors.white
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _feeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText:
                                  'Custom Ticket Entry Price (${_liveCtrl.currencySymbol.value})',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.all(12),
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedWallet01,
                                  size: 18,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedTick01,
                                size: 15,
                                color: Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'You earn ${_liveCtrl.currencySymbol.value}${hostNetEarning.toStringAsFixed(2)} per ticket (after platform commission)',
                                  style: const TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isStarting ? null : _startBroadcast,
                icon: _isStarting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const HugeIcon(
                        icon: HugeIcons.strokeRoundedVideo02,
                        color: Colors.white,
                        size: 20,
                      ),
                label: Text(
                  _isStarting ? 'Starting Live Studio...' : 'Go Live Now',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreviewStage(dynamic user, double entryFeeVal) {
    final previewTitle = _titleCtrl.text.trim().isEmpty
        ? 'What are you streaming today?'
        : _titleCtrl.text.trim();
    final hostName = _selectedIdentityName ?? user?.name ?? 'Creator';
    final hostAvatar = (_selectedIdentityAvatar?.isNotEmpty == true)
        ? _selectedIdentityAvatar!
        : (user?.avatar ?? '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE DISCOVERY CARD PREVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentCategoryLabel,
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_thumbnailFile != null)
                    Image.file(_thumbnailFile!, fit: BoxFit.cover)
                  else if (hostAvatar.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: hostAvatar,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          Container(color: const Color(0xFF1E1B4B)),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF1E1B4B),
                            Color(0xFF4C1D95),
                            Color(0xFF831843),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black38,
                          Colors.transparent,
                          Colors.black87,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF2D55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedVideo02,
                                size: 11,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isPaid) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedLock,
                                  size: 11,
                                  color: Colors.black87,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${_liveCtrl.currencySymbol.value}${entryFeeVal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedView,
                            color: Colors.white,
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          previewTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF8B5CF6),
                              backgroundImage: hostAvatar.isNotEmpty
                                  ? CachedNetworkImageProvider(hostAvatar)
                                  : null,
                              child: hostAvatar.isEmpty
                                  ? const HugeIcon(
                                      icon: HugeIcons.strokeRoundedUser,
                                      size: 13,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                hostName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _selectedIdentityBadge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildIdentityOptionCard({
    required int? id,
    required String name,
    required String avatarUrl,
    required String badgeText,
    required Color badgeColor,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFanPageId = id;
          _selectedIdentityName = name;
          _selectedIdentityAvatar = avatarUrl;
          _selectedIdentityBadge = badgeText;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.07)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: badgeColor.withValues(alpha: 0.15),
              backgroundImage: avatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl.isEmpty
                  ? HugeIcon(
                      icon: id == null
                          ? HugeIcons.strokeRoundedUser
                          : HugeIcons.strokeRoundedAward01,
                      color: badgeColor,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const HugeIcon(
                      icon: HugeIcons.strokeRoundedTick01,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureMiniToggle({
    required String label,
    required dynamic hugeIcon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: hugeIcon,
                    size: 14,
                    color: value
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? const Color(0xFF8B5CF6) : const Color(0xFFCBD5E1),
              ),
              alignment: Alignment.center,
              child: HugeIcon(
                icon: value
                    ? HugeIcons.strokeRoundedTick01
                    : HugeIcons.strokeRoundedCancel01,
                color: Colors.white,
                size: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
