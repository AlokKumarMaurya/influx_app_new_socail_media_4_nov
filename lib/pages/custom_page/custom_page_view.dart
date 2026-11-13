import 'package:material_ui/material_ui.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import '../../controllers/custom_page_controller.dart';
import '../../utils/app_theme.dart';

class CustomPageView extends StatefulWidget {
  final String slug;
  final String title;

  const CustomPageView({
    super.key,
    required this.slug,
    required this.title,
  });

  @override
  State<CustomPageView> createState() => _CustomPageViewState();
}

class _CustomPageViewState extends State<CustomPageView> {
  final CustomPageController _controller = Get.find<CustomPageController>();
  Map<String, dynamic>? _pageData;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    final data = await _controller.fetchPageDetail(widget.slug);
    if (mounted) {
      setState(() {
        if (data != null) {
          _pageData = data;
        } else {
          _error = 'Failed to load page content.';
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTextStyles.h2.copyWith(color: AppColors.textMain, fontSize: 18),
        ),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textMain),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Text(
                    _error,
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: HtmlWidget(
                    _pageData?['content'] ?? '',
                    textStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                ),
    );
  }
}
