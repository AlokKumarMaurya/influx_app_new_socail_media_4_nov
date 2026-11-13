import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/blogs_controller.dart';
import '../../data/models/blog_model.dart';
import '../../utils/app_theme.dart';

class CreateBlogPage extends StatefulWidget {
  final BlogModel? editBlog;
  const CreateBlogPage({super.key, this.editBlog});

  @override
  State<CreateBlogPage> createState() => _CreateBlogPageState();
}

class _CreateBlogPageState extends State<CreateBlogPage> {
  late final BlogsController controller;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _excerptController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  final _contentFocusNode = FocusNode();

  File? _featuredImage;
  String _status = 'published';
  bool get _isEditing => widget.editBlog != null;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<BlogsController>()) {
      controller = Get.find<BlogsController>();
    } else {
      controller = Get.put(BlogsController());
    }

    if (_isEditing) {
      final blog = widget.editBlog!;
      _titleController.text = blog.title;
      _contentController.text = blog.content ?? '';
      _excerptController.text = blog.excerpt ?? '';
      _categoryController.text = blog.category ?? '';
      _tagsController.text = blog.tags ?? '';
      _status = blog.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _excerptController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _insertTag(String openTag, String closeTag) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isValid && selection.start != selection.end) {
      // Wrap selected text
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$openTag$selectedText$closeTag',
      );
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: selection.start + openTag.length + selectedText.length + closeTag.length,
      );
    } else {
      // Insert at cursor
      final pos = selection.isValid ? selection.baseOffset : text.length;
      final newText = text.substring(0, pos) + openTag + closeTag + text.substring(pos);
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: pos + openTag.length,
      );
    }

    _contentFocusNode.requestFocus();
  }

  void _insertAtCursor(String insert) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final pos = selection.isValid ? selection.baseOffset : text.length;
    final newText = text.substring(0, pos) + insert + text.substring(pos);
    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(
      offset: pos + insert.length,
    );
    _contentFocusNode.requestFocus();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _featuredImage = File(picked.path));
    }
  }

  void _showLinkDialog() {
    final urlController = TextEditingController();
    final labelController = TextEditingController();

    // Pre-fill label with selected text
    final selection = _contentController.selection;
    if (selection.isValid && selection.start != selection.end) {
      labelController.text = _contentController.text.substring(selection.start, selection.end);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('insert_link'.tr, style: TextStyle(color: AppColors.textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: 'link_text'.tr,
                hintText: 'click_here'.tr,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'url'.tr,
                hintText: 'https://',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr, style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final label = labelController.text.isEmpty ? urlController.text : labelController.text;
              final url = urlController.text;
              if (url.isNotEmpty) {
                // If text was selected, replace it
                final sel = _contentController.selection;
                if (sel.isValid && sel.start != sel.end) {
                  final text = _contentController.text;
                  final newText = text.replaceRange(
                    sel.start, sel.end,
                    '<a href="$url">$label</a>',
                  );
                  _contentController.text = newText;
                } else {
                  _insertAtCursor('<a href="$url">$label</a>');
                }
              }
            },
            child: Text('insert'.tr, style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'title_required'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'content_required'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    bool success;
    if (_isEditing) {
      success = await controller.updateBlog(
        id: widget.editBlog!.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        status: _status,
        excerpt: _excerptController.text.trim().isEmpty ? null : _excerptController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        tags: _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim(),
        featuredImage: _featuredImage,
      );
    } else {
      success = await controller.createBlog(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        status: _status,
        excerpt: _excerptController.text.trim().isEmpty ? null : _excerptController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        tags: _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim(),
        featuredImage: _featuredImage,
      );
    }

    if (success) {
      Get.back();
      Get.snackbar(
        'success'.tr,
        _isEditing ? 'blog_updated_successfully'.tr : 'blog_published_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'error'.tr,
        _isEditing ? 'failed_update_blog'.tr : 'failed_publish_blog'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
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
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.textMain, size: 24),
          onPressed: () => Get.back(),
        ),
        title: Text(_isEditing ? 'edit_blog'.tr : 'write_a_blog'.tr, style: AppTextStyles.h3),
        actions: [
          Obx(() => controller.isSubmitting.value
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _submit,
                  child: Text(
                    _isEditing ? 'update'.tr : 'publish'.tr,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                )),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Image
            _buildFeaturedImagePicker(),
            const SizedBox(height: 20),

            // Title
            _buildTextField(
              controller: _titleController,
              hint: 'blog_title'.tr,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Excerpt
            _buildTextField(
              controller: _excerptController,
              hint: 'short_excerpt_optional'.tr,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Category + Tags row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _categoryController,
                    hint: 'category'.tr,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _tagsController,
                    hint: 'tags_comma_separated'.tr,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Text('${'status'.tr}:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  _buildStatusChip('published', 'published'.tr),
                  const SizedBox(width: 8),
                  _buildStatusChip('draft', 'draft'.tr),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content label
            Text('content'.tr, style: AppTextStyles.h4),
            const SizedBox(height: 8),

            // Formatting Toolbar
            _buildFormattingToolbar(),
            const SizedBox(height: 8),

            // Content editor
            Container(
              constraints: const BoxConstraints(minHeight: 300),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _contentController,
                focusNode: _contentFocusNode,
                maxLines: null,
                minLines: 15,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: AppColors.textMain,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'start_writing_blog_content_hint'.tr,
                  hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.15),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          image: _featuredImage != null
              ? DecorationImage(image: FileImage(_featuredImage!), fit: BoxFit.cover)
              : (_isEditing && widget.editBlog?.featuredImage != null
                  ? DecorationImage(
                      image: NetworkImage(widget.editBlog!.featuredImage!),
                      fit: BoxFit.cover,
                    )
                  : null),
        ),
        child: (_featuredImage == null && !(_isEditing && widget.editBlog?.featuredImage != null))
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedImage02,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('add_featured_image'.tr,
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text('tap_to_upload_cover_photo'.tr,
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11)),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _featuredImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextStyle? style,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: style ?? TextStyle(fontSize: 14, color: AppColors.textMain),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final isSelected = _status == value;
    return GestureDetector(
      onTap: () => setState(() => _status = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (value == 'published' ? AppColors.success : Colors.orange).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected
                ? (value == 'published' ? AppColors.success : Colors.orange)
                : AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? (value == 'published' ? AppColors.success : Colors.orange)
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolbarBtn(Icons.format_bold, 'Bold', () => _insertTag('<strong>', '</strong>')),
            _toolbarBtn(Icons.format_italic, 'Italic', () => _insertTag('<em>', '</em>')),
            _toolbarBtn(Icons.format_underlined, 'Underline', () => _insertTag('<u>', '</u>')),
            _toolbarDivider(),
            _toolbarBtn(Icons.title, 'H2', () => _insertTag('<h2>', '</h2>')),
            _toolbarBtn(Icons.text_fields, 'H3', () => _insertTag('<h3>', '</h3>')),
            _toolbarDivider(),
            _toolbarBtn(Icons.format_list_bulleted, 'List', () {
              _insertAtCursor('\n<ul>\n  <li></li>\n  <li></li>\n</ul>\n');
            }),
            _toolbarBtn(Icons.format_list_numbered, 'Ordered List', () {
              _insertAtCursor('\n<ol>\n  <li></li>\n  <li></li>\n</ol>\n');
            }),
            _toolbarDivider(),
            _toolbarBtn(Icons.format_quote, 'Quote', () => _insertTag('<blockquote>', '</blockquote>')),
            _toolbarBtn(Icons.code, 'Code', () => _insertTag('<pre><code>', '</code></pre>')),
            _toolbarBtn(Icons.link, 'Link', _showLinkDialog),
            _toolbarDivider(),
            _toolbarBtn(Icons.horizontal_rule, 'Divider', () => _insertAtCursor('\n<hr>\n')),
            _toolbarBtn(Icons.text_snippet, 'Paragraph', () => _insertTag('<p>', '</p>')),
          ],
        ),
      ),
    );
  }

  Widget _toolbarBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.textMain),
        ),
      ),
    );
  }

  Widget _toolbarDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.textSecondary.withValues(alpha: 0.15),
    );
  }
}
