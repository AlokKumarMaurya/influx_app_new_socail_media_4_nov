import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../controllers/artist_profile_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_theme.dart';

class ArtistProfilePage extends StatefulWidget {
  const ArtistProfilePage({super.key});

  @override
  State<ArtistProfilePage> createState() => _ArtistProfilePageState();
}

class _ArtistProfilePageState extends State<ArtistProfilePage> {
  late final ArtistProfileController controller;

  static const Color _orange = Color(0xFFEB8428);
  static const Color _green = Color(0xFF4B8B2E);
  static const Color _purple = Color(0xFF45478F);
  static const Color _sectionBackground = Color(0xFFF5F6FA);
  static const Color _muted = Color(0xFF9CA3AF);
  static const Color _border = Color(0xFFE1E4EA);

  @override
  void initState() {
    super.initState();
    controller = Get.put(ArtistProfileController());

    final user = Get.find<AuthController>().user.value;
    controller.artistNameController.text = user?.name ?? '';
    controller.phoneNumberController.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    if (Get.isRegistered<ArtistProfileController>()) {
      Get.delete<ArtistProfileController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildVisibilitySection(),
                    _buildArtistBasicDetailsSection(),
                    _buildBodyDetailsSection(),
                    _buildInterestsSection(),
                    _buildComfortSection(),
                    _buildPhoneSection(),
                    _buildLanguagesSection(),
                    _buildArtistBioSection(),
                    _buildSubmitSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 104,
      color: _orange,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: Get.back,
              icon: const Icon(
                Icons.reply_rounded,
                color: Colors.white,
                size: 34,
              ),
              tooltip: 'Back',
            ),
          ),
          const Text(
            'CREATE ARTIST',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilitySection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Artist',
            style: TextStyle(
              fontSize: 38,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 42),
            width: 92,
            height: 5,
            decoration: BoxDecoration(
              color: _purple,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const Text(
            "Select Person's",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => Column(
              children: [
                _visibilityOption(
                  value: 'Public',
                  description: 'All hmetv users see your details',
                ),
                _visibilityOption(
                  value: 'Private',
                  description: 'Only your friends see your details',
                ),
                _visibilityOption(
                  value: 'Only Me',
                  description: 'Only you see your details',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _visibilityOption({
    required String value,
    required String description,
  }) {
    final selected = controller.selectedVisibility.value == value;
    return InkWell(
      onTap: () => controller.selectedVisibility.value = value,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _purple,
              size: 25,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistBasicDetailsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Artist Basic Details'),
          const SizedBox(height: 22),
          _fieldLabel('Artist Name'),
          const SizedBox(height: 10),
          TextField(
            controller: controller.artistNameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(hint: 'Enter Artist Name'),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyDetailsSection() {
    return Container(
      color: _sectionBackground,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Artist Body Details'),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _dropdownField(
                  label: 'Artist Gender',
                  selected: controller.selectedGender,
                  options: ArtistProfileController.genderOptions,
                  hint: 'Select Gender',
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _dropdownField(
                  label: 'Bust / Chest',
                  selected: controller.selectedBustChest,
                  options: ArtistProfileController.bustChestOptions,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _dropdownField(
                  label: 'Hip',
                  selected: controller.selectedHip,
                  options: ArtistProfileController.hipOptions,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _dropdownField(
                  label: 'Eye Color',
                  selected: controller.selectedEyeColor,
                  options: ArtistProfileController.eyeColorOptions,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _dropdownField(
            label: 'Hair Colors',
            selected: controller.selectedHairColor,
            options: ArtistProfileController.hairColorOptions,
          ),
          const SizedBox(height: 22),
          _dropdownField(
            label: 'Body Type',
            selected: controller.selectedBodyType,
            options: ArtistProfileController.bodyTypeOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Artist Interests In'),
          const SizedBox(height: 22),
          _multiSelectChips(
            options: ArtistProfileController.artistInterestOptions,
            selected: controller.selectedInterests,
          ),
        ],
      ),
    );
  }

  Widget _buildComfortSection() {
    return Container(
      color: _sectionBackground,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Comfortable with on Screen'),
          const SizedBox(height: 22),
          _multiSelectChips(
            options: ArtistProfileController.onScreenComfortOptions,
            selected: controller.selectedOnScreenComfort,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Phone Number'),
          const SizedBox(height: 12),
          TextField(
            controller: controller.phoneNumberController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 17, color: Colors.black87),
            decoration: _inputDecoration(
              hint: 'Enter Phone Number',
              prefix: const Icon(Icons.phone, color: _muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection() {
    return Container(
      color: _sectionBackground,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Languages'),
          const SizedBox(height: 22),
          _multiSelectChips(
            options: ArtistProfileController.languageOptions,
            selected: controller.selectedLanguages,
          ),
        ],
      ),
    );
  }

  Widget _buildArtistBioSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Artist BIO'),
          const SizedBox(height: 10),
          TextField(
            controller: controller.artistBioController,
            minLines: 5,
            maxLines: 7,
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration(hint: 'Write a message....'),
          ),
          const SizedBox(height: 24),
          _dropdownField(
            label: 'Manage By',
            selected: controller.selectedManagedBy,
            options: ArtistProfileController.managedByOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
      child: SizedBox(
        height: 64,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            elevation: 5,
            shadowColor: _green.withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: const Text(
            'SUBMIT',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required RxString selected,
    required List<String> options,
    String hint = 'Select',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 10),
        Obx(
          () => DropdownButtonFormField<String>(
            value: selected.value.isEmpty ? null : selected.value,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _orange,
              size: 30,
            ),
            hint: Text(
              hint,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 16),
            ),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            decoration: _inputDecoration(),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) selected.value = value;
            },
          ),
        ),
      ],
    );
  }

  Widget _multiSelectChips({
    required List<String> options,
    required RxList<String> selected,
  }) {
    return Obx(
      () => Wrap(
        spacing: 9,
        runSpacing: 10,
        children: options.map((option) {
          final isSelected = selected.contains(option);
          return InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => controller.toggleSelection(selected, option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? _green : _sectionBackground,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? _green : _muted,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    size: 22,
                    color: isSelected ? Colors.white : _muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    option,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSelected ? Colors.white : _muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w800,
        color: Colors.black,
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 16),
      prefixIcon: prefix,
      filled: true,
      fillColor: _sectionBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _orange, width: 1.6),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  void _submitForm() {
    if (!controller.validateForm()) return;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 34, 26, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 86,
                width: 86,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Details Captured!',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your artist profile details are ready. Saving and profile creation will be enabled when the artist APIs are integrated in the next update.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: 220,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OKAY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
