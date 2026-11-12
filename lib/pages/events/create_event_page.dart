import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/events_controller.dart';
import '../../data/models/event_model.dart';
import '../../utils/app_theme.dart';

class CreateEventPage extends StatefulWidget {
  final EventModel? editEvent;
  const CreateEventPage({super.key, this.editEvent});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkController = TextEditingController();
  final _ticketPriceController = TextEditingController();

  String _selectedType = 'in_person';
  String _selectedCategory = 'Conference';
  bool _isPaid = false;
  DateTime? _startDate;
  DateTime? _endDate;
  File? _coverImage;
  String? _existingCoverUrl;
  final List<File> _materials = [];

  bool get isEditing => widget.editEvent != null;

  final List<String> _categories = [
    'Conference',
    'Workshop',
    'Meetup',
    'Party',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final e = widget.editEvent!;
      _nameController.text = e.name;
      _descriptionController.text = e.description ?? '';
      _locationController.text = e.location ?? '';
      _linkController.text = e.link ?? '';
      _selectedType = e.type;
      _selectedCategory = e.category ?? 'Conference';
      _startDate = e.startDate;
      _endDate = e.endDate;
      _existingCoverUrl = e.coverImage;
      _isPaid = e.isPaid;
      _ticketPriceController.text = e.ticketPrice > 0
          ? e.ticketPrice.toStringAsFixed(2)
          : '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    _ticketPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() {
        _coverImage = File(picked.path);
      });
    }
  }

  Future<void> _pickMaterials() async {
    final result = await FilePicker.pickFiles(allowMultiple: true);
    if (result.isNotEmpty) {
      setState(() {
        _materials.addAll(
          result.where((f) => f.path != null).map((f) => File(f.path!)),
        );
      });
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          (isStart ? _startDate : _endDate) ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _startDate = dateTime;
      } else {
        _endDate = dateTime;
      }
    });
  }

  String _formatDateForApi(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:00';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      Get.snackbar(
        'error'.tr,
        'please_select_start_date'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final controller = Get.isRegistered<EventsController>()
        ? Get.find<EventsController>()
        : Get.put(EventsController());

    final price = _isPaid
        ? (double.tryParse(_ticketPriceController.text.trim()) ?? 0.0)
        : 0.0;

    bool success;
    if (isEditing) {
      success = await controller.updateEvent(
        id: widget.editEvent!.id,
        name: _nameController.text.trim(),
        type: _selectedType,
        category: _selectedCategory,
        startDate: _formatDateForApi(_startDate!),
        endDate: _endDate != null ? _formatDateForApi(_endDate!) : null,
        location: _selectedType == 'in_person'
            ? _locationController.text.trim()
            : null,
        link: _selectedType == 'online' ? _linkController.text.trim() : null,
        description: _descriptionController.text.trim(),
        isPaid: _isPaid,
        ticketPrice: price,
        coverImage: _coverImage,
        materials: _materials.isNotEmpty ? _materials : null,
      );
    } else {
      success = await controller.createEvent(
        name: _nameController.text.trim(),
        type: _selectedType,
        category: _selectedCategory,
        startDate: _formatDateForApi(_startDate!),
        endDate: _endDate != null ? _formatDateForApi(_endDate!) : null,
        location: _selectedType == 'in_person'
            ? _locationController.text.trim()
            : null,
        link: _selectedType == 'online' ? _linkController.text.trim() : null,
        description: _descriptionController.text.trim(),
        isPaid: _isPaid,
        ticketPrice: price,
        coverImage: _coverImage,
        materials: _materials.isNotEmpty ? _materials : null,
      );
    }

    if (success) {
      Get.back();
      Get.snackbar(
        'success'.tr,
        isEditing
            ? 'event_updated_successfully'.tr
            : 'event_created_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<EventsController>()
        ? Get.find<EventsController>()
        : Get.put(EventsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textMain,
            size: 24,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isEditing ? 'edit_event'.tr : 'create_event'.tr,
          style: AppTextStyles.h3,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                    image: _coverImage != null
                        ? DecorationImage(
                            image: FileImage(_coverImage!),
                            fit: BoxFit.cover,
                          )
                        : (_existingCoverUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_existingCoverUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null),
                  ),
                  child: (_coverImage == null && _existingCoverUrl == null)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedImage01,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'tap_upload_cover_photo'.tr,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              // Event Name
              _buildLabel('event_name'.tr),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('eg_summer_music_festival'.tr),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'name_required'.tr : null,
              ),

              const SizedBox(height: 16),

              // Category & Type row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('category'.tr),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: _inputDecoration(''),
                          items: _categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('event_type'.tr),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedType,
                          decoration: _inputDecoration(''),
                          items: [
                            DropdownMenuItem(
                              value: 'in_person',
                              child: Text(
                                'in_person'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'online',
                              child: Text(
                                'online'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _selectedType = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Ticket Pricing
              _buildLabel('ticket_pricing'.tr),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text('free_event'.tr)),
                      selected: !_isPaid,
                      onSelected: (val) => setState(() => _isPaid = !val),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: !_isPaid
                            ? AppColors.primary
                            : AppColors.textMain,
                        fontWeight: !_isPaid
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text('paid_ticket'.tr)),
                      selected: _isPaid,
                      onSelected: (val) => setState(() => _isPaid = val),
                      selectedColor: Colors.amber.shade100,
                      labelStyle: TextStyle(
                        color: _isPaid
                            ? Colors.amber.shade900
                            : AppColors.textMain,
                        fontWeight: _isPaid
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isPaid) ...[
                const SizedBox(height: 12),
                _buildLabel('ticket_price'.tr),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _ticketPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration('0.00'),
                  validator: (v) {
                    if (_isPaid) {
                      if (v == null || v.trim().isEmpty)
                        return 'price_required'.tr;
                      final p = double.tryParse(v.trim());
                      if (p == null || p < 0)
                        return 'enter_valid_ticket_price'.tr;
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Start/End date row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('start_date_time'.tr),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _pickDateTime(isStart: true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _startDate != null
                                        ? _formatDateTime(_startDate!)
                                        : 'select_date'.tr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _startDate != null
                                          ? AppColors.textMain
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('end_date_time_optional'.tr),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _pickDateTime(isStart: false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _endDate != null
                                        ? _formatDateTime(_endDate!)
                                        : 'select_date'.tr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _endDate != null
                                          ? AppColors.textMain
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Location (in_person) or Link (online)
              if (_selectedType == 'in_person') ...[
                _buildLabel('location'.tr),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _locationController,
                  decoration: _inputDecoration('full_address'.tr),
                  validator: (v) {
                    if (_selectedType == 'in_person' &&
                        (v == null || v.trim().isEmpty)) {
                      return 'location_required_in_person'.tr;
                    }
                    return null;
                  },
                ),
              ],

              if (_selectedType == 'online') ...[
                _buildLabel('meeting_link'.tr),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _linkController,
                  decoration: _inputDecoration('https://zoom.us/...'),
                  keyboardType: TextInputType.url,
                  validator: (v) {
                    if (_selectedType == 'online' &&
                        (v == null || v.trim().isEmpty)) {
                      return 'link_required_online'.tr;
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Description
              _buildLabel('description'.tr),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('what_is_event_about'.tr),
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'description_required'.tr
                    : null,
              ),

              const SizedBox(height: 16),

              // Event Materials (Optional)
              _buildLabel('event_materials_manuals_optional'.tr),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickMaterials,
                icon: const Icon(Icons.attach_file, size: 18),
                label: Text('add_document_manual'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_materials.isNotEmpty) ...[
                const SizedBox(height: 8),
                Column(
                  children: _materials.map((m) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.description,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      title: Text(
                        m.path.split('/').last,
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () => setState(() => _materials.remove(m)),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 28),

              // Submit button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEditing ? 'save_changes'.tr : 'create_event'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withValues(alpha: 0.6),
        fontSize: 14,
      ),
      filled: true,
      fillColor: AppColors.cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
