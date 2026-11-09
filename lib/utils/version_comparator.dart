class VersionComparator {
  /// Compares two version strings (e.g., '1.0.0', '1.0.2', '2.0.0+1').
  /// Returns:
  ///   -1 if v1 < v2
  ///    0 if v1 == v2
  ///    1 if v1 > v2
  static int compare(String v1, String v2) {
    List<int> parseVersion(String v) {
      // Remove build metadata (e.g. "+1") and whitespace
      final clean = v.split('+').first.trim();
      return clean.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    }

    final parts1 = parseVersion(v1);
    final parts2 = parseVersion(v2);

    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    return 0;
  }

  /// Returns true if [currentVersion] is strictly lower than [targetVersion].
  static bool isLowerThan(String currentVersion, String targetVersion) {
    if (targetVersion.trim().isEmpty) return false;
    return compare(currentVersion, targetVersion) < 0;
  }
}
