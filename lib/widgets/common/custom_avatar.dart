import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../utils/app_theme.dart';
import './custom_network_image.dart';

class CustomAvatar extends StatelessWidget {
  final UserModel? user;
  final String? avatarUrl;
  final String? name;
  final double radius;
  final double? fontSize;
  final bool isOnline;

  const CustomAvatar({
    super.key,
    this.user,
    this.avatarUrl,
    this.name,
    this.radius = 20,
    this.fontSize,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    String? finalAvatar = avatarUrl ?? user?.avatar;
    bool hasAvatar = finalAvatar != null && finalAvatar.isNotEmpty;
    
    return Stack(
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: ClipOval(
            child: hasAvatar 
                ? CustomNetworkImage(
                    imageUrl: finalAvatar,
                    fit: BoxFit.cover,
                    shape: BoxShape.circle,
                    width: radius * 2,
                    height: radius * 2,
                    errorWidget: Image.asset(
                      'assets/images/img/user_avatar.png',
                      fit: BoxFit.cover,
                      width: radius * 2,
                      height: radius * 2,
                    ),
                  )
                : Image.asset(
                    'assets/images/img/user_avatar.png',
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50), // Green indicator
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cardBg,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
