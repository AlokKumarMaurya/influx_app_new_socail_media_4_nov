class ProfileCustomFieldModel {
  final int id;
  final String name;
  final String label;
  final String type;
  final List<String> options;
  final String? placeholder;
  final String? helpText;
  final bool isRequired;
  final bool showOnProfile;
  final int order;
  final bool isActive;

  ProfileCustomFieldModel({
    required this.id,
    required this.name,
    required this.label,
    required this.type,
    this.options = const [],
    this.placeholder,
    this.helpText,
    this.isRequired = false,
    this.showOnProfile = true,
    this.order = 0,
    this.isActive = true,
  });

  factory ProfileCustomFieldModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];
    if (json['options'] != null) {
      if (json['options'] is List) {
        parsedOptions = (json['options'] as List).map((e) => e.toString()).toList();
      } else if (json['options'] is String) {
        parsedOptions = (json['options'] as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return ProfileCustomFieldModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      options: parsedOptions,
      placeholder: json['placeholder']?.toString(),
      helpText: json['help_text']?.toString(),
      isRequired: json['is_required'] == true || json['is_required'] == 1 || json['is_required'] == '1',
      showOnProfile: json['show_on_profile'] == true || json['show_on_profile'] == 1 || json['show_on_profile'] == '1',
      order: int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
    );
  }
}
