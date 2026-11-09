class AppControlModel {
  final bool maintenanceMode;
  final String maintenanceTitle;
  final String maintenanceMessage;
  final String minVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String updateTitle;
  final String updateMessage;
  final String releaseNotes;
  final String playStoreUrl;
  final String appStoreUrl;

  const AppControlModel({
    this.maintenanceMode = false,
    this.maintenanceTitle = 'Under Scheduled Maintenance',
    this.maintenanceMessage =
        'We are currently performing scheduled maintenance to improve your experience. Please check back shortly.',
    this.minVersion = '1.0.0',
    this.latestVersion = '1.0.0',
    this.forceUpdate = true,
    this.updateTitle = 'Update Required',
    this.updateMessage = 'Please update your app, to continue using the app.',
    this.releaseNotes = '',
    this.playStoreUrl = '',
    this.appStoreUrl = '',
  });

  factory AppControlModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppControlModel();

    return AppControlModel(
      maintenanceMode: json['maintenance_mode'] == true,
      maintenanceTitle: json['maintenance_title']?.toString() ??
          'Under Scheduled Maintenance',
      maintenanceMessage: json['maintenance_message']?.toString() ??
          'We are currently performing scheduled maintenance to improve your experience. Please check back shortly.',
      minVersion: json['min_version']?.toString() ?? '1.0.0',
      latestVersion: json['latest_version']?.toString() ?? '1.0.0',
      forceUpdate: json['force_update'] == true,
      updateTitle: json['update_title']?.toString() ?? 'Update Required',
      updateMessage: json['update_message']?.toString() ??
          'Please update your app, to continue using the app.',
      releaseNotes: json['release_notes']?.toString() ?? '',
      playStoreUrl: json['play_store_url']?.toString() ?? '',
      appStoreUrl: json['app_store_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenance_mode': maintenanceMode,
      'maintenance_title': maintenanceTitle,
      'maintenance_message': maintenanceMessage,
      'min_version': minVersion,
      'latest_version': latestVersion,
      'force_update': forceUpdate,
      'update_title': updateTitle,
      'update_message': updateMessage,
      'release_notes': releaseNotes,
      'play_store_url': playStoreUrl,
      'app_store_url': appStoreUrl,
    };
  }
}
