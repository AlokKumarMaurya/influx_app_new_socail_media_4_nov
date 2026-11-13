import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../config/app_config.dart';
import '../l10n/app_localizations.dart';

class LanguageController extends GetxController {
  final GetStorage _storage = GetStorage();
  final String _storageKey = 'app_language';

  late final Rx<Locale> currentLocale;

  LanguageController() {
    final savedLang = _storage.read<String>(_storageKey);
    final defaultLang = AppConfig.defaultLanguage;
    final initialLang = (savedLang != null && _isSupported(savedLang))
        ? savedLang
        : (_isSupported(defaultLang) ? defaultLang : 'en');

    currentLocale = Locale(initialLang).obs;
    if (savedLang == null) {
      _storage.write(_storageKey, initialLang);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadSavedLocale();
  }

  @override
  void onReady() {
    super.onReady();
    // Ensure GetX runtime and translations are synced with the active locale
    Get.updateLocale(currentLocale.value);
  }

  void _loadSavedLocale() {
    final savedLang = _storage.read<String>(_storageKey);
    final defaultLang = AppConfig.defaultLanguage;
    final initialLang = (savedLang != null && _isSupported(savedLang))
        ? savedLang
        : (_isSupported(defaultLang) ? defaultLang : 'en');

    currentLocale.value = Locale(initialLang);
    if (savedLang == null) {
      _storage.write(_storageKey, initialLang);
    }
    Get.locale = Locale(initialLang);
  }

  void changeLanguage(String languageCode) {
    if (_isSupported(languageCode)) {
      final newLocale = Locale(languageCode);
      currentLocale.value = newLocale;
      _storage.write(_storageKey, languageCode);
      Get.updateLocale(newLocale);
    }
  }

  bool _isSupported(String code) {
    return AppLocalizations.supportedLocales.any((l) => l.languageCode == code);
  }
}
