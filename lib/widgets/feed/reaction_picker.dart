import 'package:flutter/material.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String) onReactionSelected;

  const ReactionPicker({super.key, required this.onReactionSelected});

  static const reactions = [
    {'type': 'like', 'emoji': '👍', 'label': 'Like'},
    {'type': 'love', 'emoji': '❤️', 'label': 'Love'},
    {'type': 'haha', 'emoji': '😂', 'label': 'Haha'},
    {'type': 'care', 'emoji': '🥰', 'label': 'Care'},
    {'type': 'wow', 'emoji': '😮', 'label': 'Wow'},
    {'type': 'sad', 'emoji': '😢', 'label': 'Sad'},
    {'type': 'angry', 'emoji': '😡', 'label': 'Angry'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.asMap().entries.map((entry) {
          final index = entry.key;
          final r = entry.value;
          return ReactionItem(
            type: r['type'] as String,
            emoji: r['emoji'] as String,
            label: r['label'] as String,
            index: index,
            onTap: () => onReactionSelected(r['type'] as String),
          );
        }).toList(),
      ),
    );
  }
}

class ReactionItem extends StatefulWidget {
  final String type;
  final String emoji;
  final String label;
  final int index;
  final VoidCallback onTap;

  const ReactionItem({
    super.key,
    required this.type,
    required this.emoji,
    required this.label,
    required this.index,
    required this.onTap,
  });

  @override
  State<ReactionItem> createState() => _ReactionItemState();
}

class _ReactionItemState extends State<ReactionItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Sequence entrance animation
    _entranceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: ModalRoute.of(context)?.animation ?? AlwaysStoppedAnimation(1.0),
        curve: Interval(
          (0.1 * widget.index).clamp(0.0, 1.0),
          (0.1 * widget.index + 0.4).clamp(0.0, 1.0),
          curve: Curves.elasticOut,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: ScaleTransition(
                scale: _entranceAnimation,
                child: child,
              ),
            );
          },
          child: Tooltip(
            message: widget.label,
            child: Text(
              widget.emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
      ),
    );
  }
}
