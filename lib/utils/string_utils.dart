extension StringCapitalizeExtension on String? {
  /// Returns the string with the first letter capitalized.
  /// Returns null if the string is null, or empty string if empty.
  String? get capitalizeFirst {
    if (this == null || this!.isEmpty) return this;
    return this![0].toUpperCase() + this!.substring(1);
  }

  /// Capitalizes each word separated by spaces or underscores.
  String? get capitalizeWords {
    if (this == null || this!.isEmpty) return this;
    return this!
        .replaceAll('_', ' ')
        .split(' ')
        .map((str) => str.capitalizeFirst)
        .join(' ');
  }
}
