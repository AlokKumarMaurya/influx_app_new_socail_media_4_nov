import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'lang_en.dart';
import 'lang_bn.dart';
import 'lang_it.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': kLangEn,
        'bn': kLangBn,
        'it': kLangIt,
      };
}

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('bn'),
    Locale('it'),
  ];

  static const Map<String, Map<String, String>> _values = {
    'en': kLangEn,
    'bn': kLangBn,
    'it': kLangIt,
  };

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  String _t(String key) {
    final lang = locale.languageCode;
    return _values[lang]?[key] ?? _values['en']?[key] ?? key;
  }

  String tr(String key) => _t(key);

  String get welcome => _t('welcome');
  String get login => _t('login');
  String get signup => _t('signup');
  String get email => _t('email');
  String get password => _t('password');
  String get confirmPassword => _t('confirmPassword');
  String get forgotPassword => _t('forgotPassword');
  String get submit => _t('submit');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get search => _t('search');
  String get dashboard => _t('dashboard');
  String get settings => _t('settings');
  String get language => _t('language');
  String get selectLanguage => _t('selectLanguage');
  String get profile => _t('profile');
  String get logout => _t('logout');
  String get home => _t('home');
  String get explore => _t('explore');
  String get notifications => _t('notifications');
  String get messages => _t('messages');
  String get watch => _t('watch');
  String get marketplace => _t('marketplace');
  String get groups => _t('groups');
  String get events => _t('events');
  String get campaigns => _t('campaigns');
  String get creatorHub => _t('creatorHub');
  String get forums => _t('forums');
  String get threads => _t('threads');
  String get wallet => _t('wallet');
  String get helpAndSupport => _t('helpAndSupport');
  String get settingsAndPrivacy => _t('settingsAndPrivacy');

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
