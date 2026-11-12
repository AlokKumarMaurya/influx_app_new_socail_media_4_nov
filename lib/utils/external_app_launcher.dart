import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// External companion-app URLs. Replace each TODO with the production URL
/// supplied for the corresponding application.
class ExternalAppLinks {
  static const String hamiMall = 'https://play.google.com/store/apps/details?id=com.hme.mall';
  static const String hamiBusiness = 'https://play.google.com/store/apps/details?id=com.hmetv.company';
  static const String hamiMitr = 'https://play.google.com/store/apps/details?id=com.hmetv.mitra';
}

class ExternalAppLauncher {
  static Future<void> launch(
    BuildContext context, {
    required String url,
    required String appName,
  }) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$appName link will be added soon.')),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $appName.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $appName.')),
        );
      }
    }
  }
}
