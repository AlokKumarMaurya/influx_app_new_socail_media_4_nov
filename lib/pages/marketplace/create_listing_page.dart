import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/marketplace_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/marketplace_custom_field_model.dart';
import '../../data/services/marketplace_service.dart';
import '../../data/providers/api_client.dart';
import '../../utils/app_theme.dart';
import 'product_detail_page.dart';

class CreateListingPage extends StatefulWidget {
  final ProductModel? product;

  const CreateListingPage({super.key, this.product});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final MarketplaceController controller = Get.put(MarketplaceController());
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  int? _selectedCategoryId;
  List<int> _selectedCascadeIds = [];
  String _selectedCondition = 'new';

  List<MarketplaceCustomFieldModel> _customFields = [];
  bool _isLoadingCustomFields = false;
  final Map<String, TextEditingController> _customFieldControllers = {};
  final Map<String, String?> _customFieldSelected = {};
  final Map<String, List<String>> _customFieldCheckboxes = {};

  List<String> _locationSuggestions = [];
  bool _isSearchingLocation = false;
  Timer? _locationDebounce;

  List<CategoryModel> _getCategoryPath(List<CategoryModel> tree, int targetId) {
    List<CategoryModel>? walk(List<CategoryModel> nodes, List<CategoryModel> path) {
      for (final node in nodes) {
        final currentPath = [...path, node];
        if (node.id == targetId) return currentPath;
        if (node.children.isNotEmpty) {
          final res = walk(node.children, currentPath);
          if (res != null) return res;
        }
      }
      return null;
    }
    return walk(tree, []) ?? [];
  }

  Widget _buildCategoryPicker() {
    return Obx(() {
      final rootCats = controller.categories;
      if (rootCats.isEmpty) {
        return const SizedBox.shrink();
      }

      if (_selectedCategoryId != null && _selectedCascadeIds.isEmpty) {
        final path = _getCategoryPath(rootCats, _selectedCategoryId!);
        if (path.isNotEmpty) {
          _selectedCascadeIds = path.map((c) => c.id).toList();
        }
      }

      final List<Widget> levelWidgets = [];
      List<CategoryModel> currentLevelOptions = rootCats;
      int level = 0;

      while (currentLevelOptions.isNotEmpty) {
        final int currentLevel = level;
        final List<CategoryModel> options = currentLevelOptions;
        final int? selectedValue = (currentLevel < _selectedCascadeIds.length)
            ? _selectedCascadeIds[currentLevel]
            : null;

        final String hintText = currentLevel == 0
            ? 'Select Main Category'
            : currentLevel == 1
                ? 'Select Sub Category'
                : 'Select Level ${currentLevel + 1} Sub Category';

        levelWidgets.add(
          Padding(
            padding: EdgeInsets.only(top: currentLevel == 0 ? 0 : 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: options.any((c) => c.id == selectedValue) ? selectedValue : null,
                  hint: Text(
                    hintText,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                  isExpanded: true,
                  dropdownColor: AppColors.cardBg,
                  icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                  items: options.map((cat) {
                    return DropdownMenuItem<int>(
                      value: cat.id,
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMain,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      if (_selectedCascadeIds.length > currentLevel) {
                        _selectedCascadeIds = _selectedCascadeIds.sublist(0, currentLevel);
                      }
                      if (value != null) {
                        _selectedCascadeIds.add(value);
                        _selectedCategoryId = value;
                      } else {
                        _selectedCategoryId = _selectedCascadeIds.isNotEmpty
                            ? _selectedCascadeIds.last
                            : null;
                      }
                    });
                    _loadCustomFields(_selectedCategoryId);
                  },
                ),
              ),
            ),
          ),
        );

        if (selectedValue != null) {
          final selectedCat = options.firstWhereOrNull((c) => c.id == selectedValue);
          if (selectedCat != null && selectedCat.children.isNotEmpty) {
            currentLevelOptions = selectedCat.children;
            level++;
          } else {
            break;
          }
        } else {
          break;
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: levelWidgets,
      );
    });
  }
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  static const List<Map<String, String>> _conditions = [
    {'key': 'new', 'label': 'Brand New', 'icon': '✨'},
    {'key': 'used_like_new', 'label': 'Like New', 'icon': '👌'},
    {'key': 'used_good', 'label': 'Good', 'icon': '👍'},
    {'key': 'used_fair', 'label': 'Fair', 'icon': '🤏'},
  ];

  List<Map<String, dynamic>> _availableTemplates = [];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _titleController.text = widget.product!.title;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _locationController.text = widget.product!.location ?? '';
      _selectedCategoryId = widget.product!.categoryId;
      _selectedCondition = widget.product!.condition;
    }
    _fetchDescriptionTemplates(autoFillFirst: false);
    _loadCustomFields(_selectedCategoryId);
  }

  Future<void> _loadCustomFields([int? categoryId]) async {
    setState(() {
      _isLoadingCustomFields = true;
    });
    try {
      final list = await MarketplaceService().getCustomFields(categoryId);
      final fields = list.map((e) => MarketplaceCustomFieldModel.fromJson(e)).toList();
      final existingData = widget.product?.customFieldsData ?? {};

      for (var f in fields) {
        final existingVal = existingData[f.name];
        if (['select', 'radio'].contains(f.type)) {
          _customFieldSelected[f.name] = existingVal?.toString();
        } else if (f.type == 'checkbox') {
          if (existingVal is List) {
            _customFieldCheckboxes[f.name] = existingVal.map((e) => e.toString()).toList();
          } else {
            _customFieldCheckboxes[f.name] = [];
          }
        } else {
          _customFieldControllers[f.name] = TextEditingController(text: existingVal?.toString() ?? '');
        }
      }

      setState(() {
        _customFields = fields;
      });
    } catch (e) {
      Get.log('Error loading marketplace custom fields: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCustomFields = false;
        });
      }
    }
  }

  void _searchOsmLocation(String query) {
    _locationDebounce?.cancel();
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) {
      setState(() {
        _locationSuggestions = [];
        _isSearchingLocation = false;
      });
      return;
    }

    setState(() {
      _isSearchingLocation = true;
    });

    _locationDebounce = Timer(const Duration(milliseconds: 300), () async {
      final Set<String> results = {};
      final dio = Dio();

      // 1. Try Nominatim API
      try {
        final response = await dio.get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {
            'format': 'json',
            'q': cleanQuery,
            'addressdetails': 1,
            'limit': 5,
          },
          options: Options(
            headers: {
              'User-Agent': 'InfluxApp/1.0 (com.hme.company)',
              'Accept-Language': 'en',
            },
          ),
        );

        if (response.statusCode == 200 && response.data is List) {
          for (final item in response.data) {
            final address = item['address'] as Map<String, dynamic>? ?? {};
            final List<String> parts = [];

            final name = item['name']?.toString() ?? address['town']?.toString() ?? address['city']?.toString() ?? address['village']?.toString();
            if (name != null && name.isNotEmpty) parts.add(name);

            final city = address['city']?.toString() ?? address['town']?.toString() ?? address['village']?.toString() ?? address['county']?.toString();
            if (city != null && city.isNotEmpty && !parts.contains(city)) parts.add(city);

            final state = address['state']?.toString();
            if (state != null && state.isNotEmpty && !parts.contains(state)) parts.add(state);

            final country = address['country']?.toString();
            if (country != null && country.isNotEmpty && !parts.contains(country)) parts.add(country);

            final formatted = parts.join(', ');
            if (formatted.isNotEmpty) {
              results.add(formatted);
            } else if (item['display_name'] != null) {
              results.add(item['display_name'].toString());
            }
          }
        }
      } catch (_) {}

      // 2. Fallback to Photon API if Nominatim returns empty
      if (results.isEmpty) {
        try {
          final response = await dio.get(
            'https://photon.komoot.io/api/',
            queryParameters: {'q': cleanQuery, 'limit': 5},
            options: Options(
              headers: {
                'User-Agent': 'InfluxApp/1.0 (com.hme.company)',
              },
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            final List features = response.data['features'] ?? [];
            for (final f in features) {
              final props = f['properties'] as Map<String, dynamic>? ?? {};
              final List<String> parts = [];

              if (props['name'] != null) parts.add(props['name'].toString());
              if (props['city'] != null) {
                parts.add(props['city'].toString());
              } else if (props['town'] != null) {
                parts.add(props['town'].toString());
              } else if (props['village'] != null) {
                parts.add(props['village'].toString());
              }
              if (props['state'] != null) parts.add(props['state'].toString());
              if (props['country'] != null) parts.add(props['country'].toString());

              final uniqueParts = <String>[];
              for (final p in parts) {
                if (!uniqueParts.contains(p)) uniqueParts.add(p);
              }
              final String formatted = uniqueParts.join(', ');
              if (formatted.isNotEmpty) {
                results.add(formatted);
              }
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _locationSuggestions = results.toList();
          _isSearchingLocation = false;
        });
      }
    });
  }

  Future<void> _fetchDescriptionTemplates({bool autoFillFirst = false}) async {
    try {
      final response = await ApiClient().dio.get('/app-config');
      if (response.data != null && response.data['data'] != null) {
        final rawList = response.data['data']['product_description_templates'];
        if (rawList is List) {
          _availableTemplates = rawList.map((item) => Map<String, dynamic>.from(item)).toList();
          if (autoFillFirst && _availableTemplates.isNotEmpty && _descriptionController.text.isEmpty) {
            if (mounted) {
              setState(() {
                _descriptionController.text = _availableTemplates.first['content']?.toString() ?? '';
              });
            }
          }
        }
      }
    } catch (e) {
      Get.log('Error fetching description templates: $e');
    }
  }

  void _showTemplateSelectorSheet() {
    if (_availableTemplates.isEmpty) {
      _fetchDescriptionTemplates().then((_) {
        if (_availableTemplates.isEmpty) {
          Get.snackbar('notice'.tr, 'no_templates_available'.tr,
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
        _renderTemplateBottomSheet();
      });
    } else {
      _renderTemplateBottomSheet();
    }
  }

  void _renderTemplateBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedDocumentAttachment,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'select_description_template'.tr,
                  style: AppTextStyles.h4,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _availableTemplates.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tpl = _availableTemplates[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    title: Text(
                      tpl['title'] ?? '${'template'.tr} #${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      tpl['content'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      setState(() {
                        _descriptionController.text = tpl['content'] ?? '';
                      });
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationDebounce?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isNotEmpty) {
      setState(() {
        for (final img in images) {
          if (_selectedImages.length < 10) {
            _selectedImages.add(File(img.path));
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      Get.snackbar('required'.tr, 'please_select_category'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[400],
          colorText: Colors.white);
      return;
    }

    try {
      final customFieldsPayload = <String, dynamic>{};
      for (var f in _customFields) {
        if (['select', 'radio'].contains(f.type)) {
          if (_customFieldSelected[f.name] != null) {
            customFieldsPayload[f.name] = _customFieldSelected[f.name];
          }
        } else if (f.type == 'checkbox') {
          if (_customFieldCheckboxes[f.name] != null) {
            customFieldsPayload[f.name] = _customFieldCheckboxes[f.name];
          }
        } else {
          if (_customFieldControllers[f.name] != null) {
            customFieldsPayload[f.name] = _customFieldControllers[f.name]!.text.trim();
          }
        }
      }

      if (widget.product != null) {
        // Update
        final success = await controller.updateListing(
          widget.product!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          categoryId: _selectedCategoryId!,
          condition: _selectedCondition,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          customFields: customFieldsPayload,
          images: _selectedImages.isNotEmpty ? _selectedImages : null,
        );

        if (success) {
          Get.back(); // Return to previous screen
          Get.snackbar('success'.tr, 'listing_updated_success'.tr,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white);
        } else {
            throw Exception('Update failed');
        }
      } else {
        // Create
        final product = await controller.createListing(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          categoryId: _selectedCategoryId!,
          condition: _selectedCondition,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          customFields: customFieldsPayload,
          images: _selectedImages.isNotEmpty ? _selectedImages : null,
        );

        if (product != null) {
          Get.off(() => ProductDetailPage(productId: product.id));
          Get.snackbar('success'.tr, 'listing_published_success'.tr,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_save_listing'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[400],
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            color: AppColors.textMain,
            size: 22,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.product != null ? 'Edit Listing' : 'New Listing',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              _buildImageSection(),
              const SizedBox(height: 24),

              // Title
              _buildLabel('Item Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hint: 'What are you selling?',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),

              // Price
              _buildLabel('Price'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _priceController,
                hint: '0.00',
                prefixText: '${Get.isRegistered<SettingsController>() ? Get.find<SettingsController>().currencySymbol.value : '\$'} ',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Price is required';
                  if (double.tryParse(v) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category
              _buildLabel('Category'),
              const SizedBox(height: 8),
              _buildCategoryPicker(),
              const SizedBox(height: 20),

              // Condition
              _buildLabel('Condition'),
              const SizedBox(height: 8),
              _buildConditionSelector(),
              const SizedBox(height: 20),

              // Description
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Description'),
                  GestureDetector(
                    onTap: _showTemplateSelectorSheet,
                    child: Text(
                      'Select Template',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint: 'What\'s special about your item? Include details about condition, features, and reason for selling.',
                maxLines: 5,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Description is required';
                  if (v.length < 10) return 'At least 10 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Location (OSM Autocomplete)
              _buildLabel('Location (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                style: TextStyle(fontSize: 14, color: AppColors.textMain),
                onChanged: _searchOsmLocation,
                decoration: InputDecoration(
                  hintText: 'search_location_placeholder'.tr,
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 20),
                  suffixIcon: _isSearchingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_locationController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _locationController.clear();
                                setState(() {
                                  _locationSuggestions = [];
                                });
                              },
                            )
                          : null),
                  fillColor: AppColors.cardBg,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              if (_isSearchingLocation || _locationSuggestions.isNotEmpty || _locationController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSearchingLocation)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Searching locations...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!_isSearchingLocation) ...[
                        // Option for Custom Location
                        if (_locationController.text.trim().isNotEmpty)
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: Icon(Icons.edit_location_alt_outlined, size: 18, color: AppColors.primary),
                            title: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'Use custom location: '),
                                  TextSpan(
                                    text: '"${_locationController.text.trim()}"',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              style: TextStyle(fontSize: 13, color: AppColors.primary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              setState(() {
                                _locationSuggestions = [];
                              });
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        if (_locationController.text.trim().isNotEmpty && _locationSuggestions.isNotEmpty)
                          Divider(
                            height: 1,
                            color: AppColors.textSecondary.withValues(alpha: 0.1),
                          ),
                        // List of OSM suggestions
                        if (_locationSuggestions.isNotEmpty)
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              itemCount: _locationSuggestions.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: AppColors.textSecondary.withValues(alpha: 0.1),
                              ),
                              itemBuilder: (context, index) {
                                final item = _locationSuggestions[index];
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading: Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                                  title: Text(
                                    item,
                                    style: TextStyle(fontSize: 13, color: AppColors.textMain),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _locationController.text = item;
                                      _locationSuggestions = [];
                                    });
                                    FocusScope.of(context).unfocus();
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],

              _buildCustomFieldsSection(),

              const SizedBox(height: 32),

              // Submit
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          controller.isCreating.value ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.5),
                      ),
                      child: controller.isCreating.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              widget.product != null ? 'Update Listing' : 'Publish Listing',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  )),
              const SizedBox(height: 20),
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
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        color: AppColors.textMain,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          fontWeight: FontWeight.w400,
        ),
        prefixText: prefixText,
        prefixStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppColors.textSecondary)
            : null,
        filled: true,
        fillColor: AppColors.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Photos'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.isDark ? Colors.white12 : Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.cloud_upload_outlined,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap to add photos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'JPEG, PNG · Max 5MB each',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImages[index],
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Cover',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }



  Widget _buildConditionSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _conditions.map((c) {
        final isActive = _selectedCondition == c['key'];
        return GestureDetector(
          onTap: () => setState(() => _selectedCondition = c['key']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppColors.primary
                    : AppColors.isDark
                        ? Colors.white12
                        : Colors.grey[300]!,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c['icon']!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  c['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.primary : AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomFieldsSection() {
    if (_isLoadingCustomFields) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'loading_additional_fields'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_customFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'item_specifications_details'.tr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._customFields.map((f) => _buildCustomFieldInput(f)),
      ],
    );
  }

  Widget _buildCustomFieldInput(MarketplaceCustomFieldModel field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLabel(field.label),
              if (field.isRequired)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _renderFieldControl(field),
        ],
      ),
    );
  }

  Widget _renderFieldControl(MarketplaceCustomFieldModel field) {
    if (field.type == 'select') {
      final options = field.options;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: options.contains(_customFieldSelected[field.name])
                ? _customFieldSelected[field.name]
                : null,
            hint: Text(
              field.placeholder?.isNotEmpty == true
                  ? field.placeholder!
                  : 'select_field'.trParams({'field': field.label}),
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
            isExpanded: true,
            dropdownColor: AppColors.cardBg,
            icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
            items: options.map((opt) {
              return DropdownMenuItem<String>(
                value: opt,
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _customFieldSelected[field.name] = val;
              });
            },
          ),
        ),
      );
    }

    if (field.type == 'radio') {
      final options = field.options;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          final isSelected = _customFieldSelected[field.name] == opt;
          return GestureDetector(
            onTap: () {
              setState(() {
                _customFieldSelected[field.name] = opt;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : (AppColors.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (AppColors.isDark ? Colors.white12 : Colors.grey[300]!),
                ),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textMain,
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    if (field.type == 'checkbox') {
      final options = field.options;
      final selectedList = _customFieldCheckboxes[field.name] ?? [];
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          final isChecked = selectedList.contains(opt);
          return FilterChip(
            label: Text(opt),
            selected: isChecked,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
              color: isChecked ? Colors.white : AppColors.textMain,
            ),
            selectedColor: AppColors.primary,
            checkmarkColor: Colors.white,
            backgroundColor: AppColors.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[100],
            onSelected: (val) {
              setState(() {
                if (val) {
                  selectedList.add(opt);
                } else {
                  selectedList.remove(opt);
                }
                _customFieldCheckboxes[field.name] = selectedList;
              });
            },
          );
        }).toList(),
      );
    }

    _customFieldControllers.putIfAbsent(field.name, () => TextEditingController());
    final ctrl = _customFieldControllers[field.name]!;

    if (field.type == 'textarea') {
      return _buildTextField(
        controller: ctrl,
        hint: field.placeholder?.isNotEmpty == true
            ? field.placeholder!
            : 'enter_field'.trParams({'field': field.label}),
        maxLines: 3,
        validator: field.isRequired
            ? (v) => v == null || v.trim().isEmpty
                ? 'field_is_required'.trParams({'field': field.label})
                : null
            : null,
      );
    }

    return _buildTextField(
      controller: ctrl,
      hint: field.placeholder?.isNotEmpty == true
          ? field.placeholder!
          : 'enter_field'.trParams({'field': field.label}),
      keyboardType: field.type == 'number'
          ? TextInputType.number
          : (field.type == 'date' ? TextInputType.datetime : TextInputType.text),
      validator: field.isRequired
          ? (v) => v == null || v.trim().isEmpty
              ? 'field_is_required'.trParams({'field': field.label})
              : null
          : null,
    );
  }
}
