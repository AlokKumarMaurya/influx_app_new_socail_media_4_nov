import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_theme.dart';

class VideoPreviewBox extends StatelessWidget {
  final String videoUrl;

  const VideoPreviewBox({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.isDark 
          ? Colors.white.withValues(alpha: 0.05) 
          : Colors.black.withValues(alpha: 0.05),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Color / Placeholder
          Container(
            color: Colors.black.withValues(alpha: 0.4),
          ),
          // Play Icon Overlay
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          // Video Tag
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam_outlined, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'video'.tr.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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
}
