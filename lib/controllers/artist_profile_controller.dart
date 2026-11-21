import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// Holds the artist creation form state and temporary option catalogues.
///
/// These lists are intentionally local for this PR. They can be replaced with
/// API-backed values in the follow-up PR without changing the form widgets.
class ArtistProfileController extends GetxController {
  static const List<String> visibilityOptions = [
    'Public',
    'Private',
    'Only Me',
  ];

  static const List<String> genderOptions = [
    'Female',
    'Male',
    'Other',
    'Prefer not to say',
  ];

  static const List<String> bustChestOptions = [
    '28', '30', '32', '34', '36', '38', '40', '42', '44', '46',
  ];

  static const List<String> hipOptions = [
    '28', '30', '32', '34', '36', '38', '40', '42', '44', '46',
  ];

  static const List<String> eyeColorOptions = [
    'Black', 'Brown', 'Blue', 'Green', 'Hazel', 'Grey', 'Other',
  ];

  static const List<String> hairColorOptions = [
    'Black', 'Brown', 'Blonde', 'Red', 'Auburn', 'Grey', 'White', 'Other',
  ];

  static const List<String> bodyTypeOptions = [
    'Slim', 'Athletic', 'Average', 'Curvy', 'Plus Size', 'Muscular',
  ];

  static const List<String> artistInterestOptions = [
    'Acting',
    'Ramp Shows',
    'Western Wears',
    'Calendar Shoots',
    'Movie',
    'Bold Webseries',
    'Ads',
    'Lingerie Shoots',
    'Semi Nude Shoots',
    'Print Shoot',
    'Designer Shoots',
    'Swim Suits',
    'Music Albums',
    'Webseries',
    'TV Serial',
    'Bikini Shoots',
    'Full Body Paint Shoots',
    'Nude Shoots',
  ];

  static const List<String> onScreenComfortOptions = [
    'Kiss',
    'Love making',
    'Western',
    'Bikini',
    'Bed Scenes',
    'Nude',
    'Smooch',
    'Shorts',
    'Able to work indoor & outdoor',
    'Bold Scenes',
    'Topless',
    'Compro or Adjustment',
  ];

  static const List<String> languageOptions = [
    'Hindi',
    'English',
    'Marathi',
    'Urdu',
    'Tamil',
    'Telugu',
    'Malayalam',
    'Spanish',
    'Russian',
    'Mandarin',
    'Arabic',
    'German',
    'French',
    'Korean',
  ];

  static const List<String> managedByOptions = [
    'Self',
    'Manager',
    'Agency',
  ];

  final artistNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final artistBioController = TextEditingController();

  final selectedVisibility = 'Public'.obs;
  final selectedGender = ''.obs;
  final selectedBustChest = ''.obs;
  final selectedHip = ''.obs;
  final selectedEyeColor = ''.obs;
  final selectedHairColor = ''.obs;
  final selectedBodyType = ''.obs;
  final selectedManagedBy = ''.obs;

  final selectedInterests = <String>[].obs;
  final selectedOnScreenComfort = <String>[].obs;
  final selectedLanguages = <String>[].obs;

  void toggleSelection(RxList<String> selection, String value) {
    if (selection.contains(value)) {
      selection.remove(value);
    } else {
      selection.add(value);
    }
  }

  bool validateForm() {
    if (artistNameController.text.trim().isEmpty) {
      Get.snackbar('Required', 'Please enter the artist name.');
      return false;
    }
    if (phoneNumberController.text.trim().isEmpty) {
      Get.snackbar('Required', 'Please enter the phone number.');
      return false;
    }
    return true;
  }

  @override
  void onClose() {
    artistNameController.dispose();
    phoneNumberController.dispose();
    artistBioController.dispose();
    super.onClose();
  }
}
