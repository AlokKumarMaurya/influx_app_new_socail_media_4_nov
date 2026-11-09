import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class EmojiPickerSheet extends StatefulWidget {
  final Function(String emoji) onEmojiSelected;

  const EmojiPickerSheet({super.key, required this.onEmojiSelected});

  @override
  State<EmojiPickerSheet> createState() => _EmojiPickerSheetState();

  static void show(BuildContext context, Function(String) onEmojiSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmojiPickerSheet(onEmojiSelected: onEmojiSelected),
    );
  }
}

class _EmojiPickerSheetState extends State<EmojiPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Map<String, List<String>> _categories = {
    '😀': [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃',
      '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😙',
      '🥲', '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫',
      '🤔', '🤐', '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬',
      '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮',
      '🥵', '🥶', '🥴', '😵', '🤯', '🤠', '🥳', '🥸', '😎', '🤓',
      '😕', '😟', '🙁', '😮', '😯', '😲', '😳', '🥺', '😦', '😧',
      '😨', '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞', '😓',
      '😩', '😫', '🥱', '😤', '😡', '😠', '🤬', '😈', '👿', '💀',
    ],
    '👋': [
      '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤌', '🤏', '✌️', '🤞',
      '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '👍',
      '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝',
      '🙏', '💪', '👀', '👅', '👄',
    ],
    '❤️': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
      '❤️‍🔥', '❤️‍🩹', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟',
    ],
    '🐶': [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
      '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🐦', '🦅', '🦆',
      '🦉', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🌸', '💐',
      '🌷', '🌹', '🌺', '🌻', '🌼', '🌿', '🍀', '🍁', '🍂', '🍃',
    ],
    '🍔': [
      '🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍈',
      '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🥑', '🥦', '🍔',
      '🍟', '🍕', '🌭', '🥪', '🌮', '🌯', '🥙', '☕', '🍵', '🍺',
    ],
    '⚽': [
      '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🎱', '🎮', '🕹️',
      '🎲', '🧩', '🎭', '🎨', '🎼', '🎵', '🎶', '🎹', '🥁', '🎸',
    ],
    '💯': [
      '💯', '✅', '❌', '❓', '❗', '💢', '💥', '💫', '💦', '💨',
      '💬', '💭', '💤', '🔊', '🔔', '🔕', '🔑', '🔒', '🔓', '🔥',
      '⭐', '🌟', '✨', '⚡', '🎉', '🎊',
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.textMain,
            unselectedLabelColor: AppColors.textSecondary.withValues(alpha: 0.5),
            labelStyle: const TextStyle(fontSize: 22),
            tabAlignment: TabAlignment.start,
            tabs: _categories.keys.map((key) => Tab(text: key)).toList(),
          ),

          // Emoji grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.values.map((emojis) {
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: emojis.length,
                  itemBuilder: (_, index) {
                    return GestureDetector(
                      onTap: () {
                        widget.onEmojiSelected(emojis[index]);
                      },
                      child: Center(
                        child: Text(
                          emojis[index],
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
