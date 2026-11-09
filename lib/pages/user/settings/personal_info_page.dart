import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/user_settings_controller.dart';
import '../../../utils/app_theme.dart';
import 'settings_widgets.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final controller = Get.find<UserSettingsController>();

  @override
  void initState() {
    super.initState();
    controller.initFields();
  }

  @override
  Widget build(BuildContext context) {

    return Obx(() => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('personal_information'.tr, style: AppTextStyles.h3),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshSettings(0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsWidgets.buildSectionHeader('general_information'.tr),
              SettingsWidgets.buildTextField('full_name'.tr, controller.nameController),
              SettingsWidgets.buildTextField('username'.tr, controller.usernameController),
              SettingsWidgets.buildTextField(
                'email'.tr,
                controller.emailController,
                trailingLabel: SettingsWidgets.buildPrivacySelector('email', controller),
              ),
              SettingsWidgets.buildTextField(
                'phone'.tr,
                controller.phoneController,
                trailingLabel: SettingsWidgets.buildPrivacySelector('phone', controller),
              ),

              const SizedBox(height: 20),
              SettingsWidgets.buildDropdown(
                'gender'.tr,
                controller.selectedGender,
                [
                  DropdownMenuItem(value: 'male', child: Text('male'.tr)),
                  DropdownMenuItem(value: 'female', child: Text('female'.tr)),
                  DropdownMenuItem(value: 'other', child: Text('other'.tr)),
                  DropdownMenuItem(
                    value: 'prefer_not_to_say',
                    child: Text('prefer_not_to_say'.tr),
                  ),
                ],
                trailingLabel: SettingsWidgets.buildPrivacySelector('gender', controller),
              ),

              const SizedBox(height: 10),
              _buildDatePicker('birth_date'.tr, controller),

              const SizedBox(height: 20),
              SettingsWidgets.buildTextField(
                'bio'.tr,
                controller.bioController,
                maxLines: 3,
                trailingLabel: SettingsWidgets.buildPrivacySelector('bio', controller),
              ),
              SettingsWidgets.buildTextField(
                'work'.tr,
                controller.workController,
                trailingLabel: SettingsWidgets.buildPrivacySelector('work', controller),
              ),
              SettingsWidgets.buildTextField(
                'education'.tr,
                controller.educationController,
                trailingLabel: SettingsWidgets.buildPrivacySelector('education', controller),
              ),
              SettingsWidgets.buildTextField(
                'website'.tr,
                controller.websiteController,
                trailingLabel: SettingsWidgets.buildPrivacySelector('website', controller),
              ),

              const SizedBox(height: 30),
              SettingsWidgets.buildSectionHeader('address_details'.tr),
              SettingsWidgets.buildTextField(
                'country'.tr,
                controller.countryController,
                trailingLabel: SettingsWidgets.buildPrivacySelector('country', controller),
              ),
              SettingsWidgets.buildTextField(
                'state'.tr,
                controller.stateController,
                trailingLabel: SettingsWidgets.buildPrivacySelector('state', controller),
              ),
              SettingsWidgets.buildTextField(
                'city'.tr,
                controller.cityController,
                trailingLabel: SettingsWidgets.buildPrivacySelector('city', controller),
              ),
              SettingsWidgets.buildTextField(
                'zip_code'.tr,
                controller.zipCodeController,
                trailingLabel: SettingsWidgets.buildPrivacySelector('zip_code', controller),
              ),
              SettingsWidgets.buildTextField(
                'address'.tr,
                controller.addressController,
                trailingLabel: SettingsWidgets.buildPrivacySelector('address', controller),
              ),
              SettingsWidgets.buildTextField(
                'personal_location'.tr,
                controller.locationController,
                trailingLabel: SettingsWidgets.buildPrivacySelector('location', controller),
              ),

              Obx(() {
                if (controller.profileCustomFields.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    SettingsWidgets.buildSectionHeader('additional_details'.tr),
                    ...controller.profileCustomFields.map((field) {
                      final ctrl = controller.customFieldControllers[field.name];
                      if (['select', 'radio'].contains(field.type)) {
                        final selectedRx = controller.customFieldSelectedOptions[field.name];
                        if (selectedRx == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SettingsWidgets.buildDropdown(
                            field.label,
                            selectedRx,
                            field.options
                                .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                                .toList(),
                          ),
                        );
                      } else if (field.type == 'checkbox') {
                        final listRx = controller.customFieldCheckboxOptions[field.name];
                        if (listRx == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(field.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                children: field.options.map((opt) {
                                  return Obx(() {
                                    final isSelected = listRx.contains(opt);
                                    return FilterChip(
                                      label: Text(opt),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          listRx.add(opt);
                                        } else {
                                          listRx.remove(opt);
                                        }
                                      },
                                    );
                                  });
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      } else {
                        if (ctrl == null) return const SizedBox.shrink();
                        return SettingsWidgets.buildTextField(
                          field.label,
                          ctrl,
                          maxLines: field.type == 'textarea' ? 3 : 1,
                        );
                      }
                    }),
                  ],
                );
              }),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.updateGeneral(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'save_changes'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildDatePicker(String label, UserSettingsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            SettingsWidgets.buildPrivacySelector('birth_date', controller),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: Get.context!,
              initialDate: controller.selectedBirthDate.value ?? DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) controller.selectedBirthDate.value = date;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    controller.selectedBirthDate.value == null
                        ? 'Select Date'
                        : DateFormat(
                            'MMM dd, yyyy',
                          ).format(controller.selectedBirthDate.value!),
                  ),
                ),
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
