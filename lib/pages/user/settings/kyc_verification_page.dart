import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../../controllers/user_settings_controller.dart';
import '../../../utils/app_theme.dart';
import 'settings_widgets.dart';

class KycVerificationPage extends StatelessWidget {
  const KycVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserSettingsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('identity_verification'.tr, style: AppTextStyles.h3),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchKycStatus(),
        child: Obx(() {
          if (controller.kycStatus.value == 'pending' || controller.kycStatus.value == 'approved') {
            return _buildStatusView(controller);
          }
          return _buildFormView(context, controller);
        }),
      ),
    );
  }

  Widget _buildStatusView(UserSettingsController controller) {
    final isApproved = controller.kycStatus.value == 'approved';
    final details = controller.kycDetails.value;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: Get.height * 0.05),
            HugeIcon(
              icon: isApproved ? HugeIcons.strokeRoundedCheckList : HugeIcons.strokeRoundedClock01,
              size: 80,
              color: isApproved ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              isApproved ? 'identity_verified'.tr : 'verification_pending'.tr,
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 12),
            Text(
              isApproved
                  ? 'kyc_approved_desc'.tr
                  : 'kyc_pending_desc'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            if (details != null) ...[
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 15),
              _buildDetailRow(
                'document_type'.tr,
                details['document_type_name'] ?? details['document_type'] ?? '',
              ),
              if (details['document_number'] != null && details['document_number'].toString().isNotEmpty)
                _buildDetailRow('id_number'.tr, details['document_number'].toString()),
              
              // Custom Dynamic Fields Data display
              if (details['fields_data'] != null && details['fields_data'] is Map) ...[
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                ...(details['fields_data'] as Map).entries.map((entry) {
                  final val = entry.value;
                  String displayVal = '';
                  String label = entry.key;
                  if (val is Map) {
                    label = val['label'] ?? entry.key;
                    if (val['type'] == 'file') {
                      displayVal = val['filename'] ?? 'attached_document'.tr;
                    } else if (val['value'] != null) {
                      displayVal = val['value'].toString();
                    }
                  } else if (val != null) {
                    displayVal = val.toString();
                  }
                  return _buildDetailRow(label, displayVal);
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, UserSettingsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Obx(() {
        final docConfig = controller.selectedDocTypeConfig;
        final numReq = docConfig?['document_number_requirement'] ?? 'required';
        final frontReq = docConfig?['front_requirement'] ?? 'required';
        final backReq = docConfig?['back_requirement'] ?? 'optional';
        final selfieReq = docConfig?['selfie_requirement'] ?? 'required';
        final applicableFields = controller.currentApplicableFields;

        // Build dropdown menu items from dynamic document types
        List<DropdownMenuItem<String>> typeItems = [];
        if (controller.kycDocumentTypes.isNotEmpty) {
          typeItems = controller.kycDocumentTypes.map((dt) {
            return DropdownMenuItem<String>(
              value: dt['slug']?.toString() ?? '',
              child: Text(dt['name']?.toString() ?? ''),
            );
          }).toList();
        } else {
          typeItems = [
            DropdownMenuItem(value: 'id_card', child: Text('national_id'.tr)),
            DropdownMenuItem(value: 'passport', child: Text('passport'.tr)),
            DropdownMenuItem(value: 'driving_license', child: Text('drivers_license'.tr)),
          ];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsWidgets.buildSectionHeader('verify_your_identity'.tr),
            Text(
              'kyc_intro_desc'.tr,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 25),

            // Document Type Dropdown
            SettingsWidgets.buildDropdown(
              'select_id_type'.tr,
              controller.selectedKycType,
              typeItems,
            ),
            if (docConfig?['description'] != null && docConfig!['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                docConfig['description'].toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 20),

            // Document Number (if not disabled)
            if (numReq != 'disabled') ...[
              SettingsWidgets.buildTextField(
                numReq == 'required' ? '${'id_number'.tr} *' : 'id_number'.tr,
                controller.kycDocNumberController,
              ),
              const SizedBox(height: 10),
            ],

            // Dynamic Custom Fields
            if (applicableFields.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'additional_information'.tr,
                style: AppTextStyles.h3.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...applicableFields.map((field) => _buildDynamicFieldWidget(context, controller, field)),
              const SizedBox(height: 10),
            ],

            // Core Identity Photos Section
            if (frontReq != 'disabled' || backReq != 'disabled' || selfieReq != 'disabled') ...[
              const SizedBox(height: 10),
              Text('upload_id_photos'.tr, style: AppTextStyles.h3),
              const SizedBox(height: 15),

              // Front and Back Row
              if (frontReq != 'disabled' || backReq != 'disabled')
                Row(
                  children: [
                    if (frontReq != 'disabled')
                      Expanded(
                        child: SettingsWidgets.buildImagePickerTile(
                          frontReq == 'required' ? '${'front_side'.tr} *' : 'front_side'.tr,
                          controller.kycFrontFile,
                          () => controller.pickKycImage('front'),
                        ),
                      ),
                    if (frontReq != 'disabled' && backReq != 'disabled')
                      const SizedBox(width: 10),
                    if (backReq != 'disabled')
                      Expanded(
                        child: SettingsWidgets.buildImagePickerTile(
                          backReq == 'required' ? '${'back_side'.tr} *' : 'back_side_optional'.tr,
                          controller.kycBackFile,
                          () => controller.pickKycImage('back'),
                        ),
                      ),
                  ],
                ),

              // Selfie Box
              if (selfieReq != 'disabled') ...[
                const SizedBox(height: 15),
                SettingsWidgets.buildImagePickerTile(
                  selfieReq == 'required' ? '${'selfie_with_id'.tr} *' : 'selfie_with_id'.tr,
                  controller.kycSelfieFile,
                  () => controller.pickKycImage('selfie'),
                  isWide: true,
                ),
              ],
            ],

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : () => controller.submitKyc(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'submit_for_verification'.tr,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        );
      }),
    );
  }

  Widget _buildDynamicFieldWidget(
    BuildContext context,
    UserSettingsController controller,
    Map<String, dynamic> field,
  ) {
    final key = field['name'] as String;
    final label = (field['label'] ?? key) + (field['is_required'] == true ? ' *' : '');
    final type = field['type'] ?? 'text';
    final placeholder = field['placeholder'] ?? '';
    final helpText = field['help_text'];

    if (type == 'textarea') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsWidgets.buildTextField(
              label,
              controller.dynamicFieldControllers[key]!,
              maxLines: 3,
            ),
            if (helpText != null && helpText.toString().isNotEmpty)
              Text(helpText.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );
    } else if (type == 'number') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: controller.dynamicFieldControllers[key]!,
              keyboardType: _getTextInputType(isDecimal: true),
              decoration: InputDecoration(
                hintText: placeholder,
                filled: true,
                fillColor: AppColors.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              ),
            ),
            if (helpText != null && helpText.toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(helpText.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ],
        ),
      );
    } else if (type == 'date') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
                );
                if (picked != null) {
                  controller.dynamicFieldControllers[key]!.text = DateFormat('yyyy-MM-dd').format(picked);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedCalendar03, size: 20, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        controller.dynamicFieldControllers[key]!.text.isEmpty
                            ? (placeholder.isNotEmpty ? placeholder : 'select_date'.tr)
                            : controller.dynamicFieldControllers[key]!.text,
                        style: TextStyle(
                          color: controller.dynamicFieldControllers[key]!.text.isEmpty ? Colors.grey : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (helpText != null && helpText.toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(helpText.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ],
        ),
      );
    } else if (type == 'select' || type == 'radio') {
      List<String> options = [];
      if (field['options'] is List) {
        options = List<String>.from(field['options']);
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: AppColors.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.dynamicSelectValues[key]?.value.isEmpty == true
                      ? null
                      : controller.dynamicSelectValues[key]?.value,
                  hint: Text(placeholder.isNotEmpty ? placeholder : 'select_option'.tr, style: const TextStyle(color: Colors.grey)),
                  isExpanded: true,
                  items: options.map((opt) {
                    return DropdownMenuItem<String>(value: opt, child: Text(opt));
                  }).toList(),
                  onChanged: (val) {
                    controller.dynamicSelectValues[key]?.value = val ?? '';
                  },
                ),
              ),
            ),
            if (helpText != null && helpText.toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(helpText.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ],
        ),
      );
    } else if (type == 'file') {
      final fileRx = controller.dynamicFieldFiles[key];
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => controller.pickDynamicFile(key),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedAttachment01, size: 24, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fileRx?.value != null
                            ? fileRx!.value!.path.split('/').last
                            : (placeholder.isNotEmpty ? placeholder : 'choose_document_or_image'.tr),
                        style: TextStyle(
                          fontSize: 13,
                          color: fileRx?.value != null ? AppColors.primary : Colors.grey,
                          fontWeight: fileRx?.value != null ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (fileRx?.value != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => fileRx?.value = null,
                      ),
                  ],
                ),
              ),
            ),
            if (helpText != null && helpText.toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(helpText.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ],
        ),
      );
    } else {
      // Default: text
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsWidgets.buildTextField(
              label,
              controller.dynamicFieldControllers[key]!,
            ),
            if (helpText != null && helpText.toString().isNotEmpty)
              Text(helpText.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );
    }
  }

  TextInputType _getTextInputType({bool isDecimal = false}) {
    return TextInputType.numberWithOptions(decimal: isDecimal);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
