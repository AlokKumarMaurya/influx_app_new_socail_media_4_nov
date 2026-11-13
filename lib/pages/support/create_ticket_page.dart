import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../controllers/support_controller.dart';
import '../../utils/app_theme.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final SupportController controller = Get.find<SupportController>();
  final _formKey = GlobalKey<FormState>();
  
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _selectedCategory = 'General Enquiry';
  String _selectedPriority = 'Medium';

  final List<String> _categories = [
    'General Enquiry',
    'Technical Issue',
    'Billing & Payments',
    'Feature Request',
    'Bug Report',
    'Other'
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('create_ticket'.tr, style: AppTextStyles.h2),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('subject'.tr, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                decoration: _inputDecoration('enter_ticket_subject'.tr),
                validator: (v) => v!.isEmpty ? 'please_enter_subject'.tr : null,
              ),
              const SizedBox(height: 20),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('category'.tr, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          isExpanded: true,
                          decoration: _inputDecoration(''),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('priority'.tr, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPriority,
                          isExpanded: true,
                          decoration: _inputDecoration(''),
                          items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (v) => setState(() => _selectedPriority = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Text('message'.tr, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: _inputDecoration('describe_issue_in_detail'.tr),
                validator: (v) => v!.isEmpty ? 'please_enter_message'.tr : null,
              ),
              const SizedBox(height: 20),
              
              Text('attachments'.tr, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...controller.selectedFiles.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: const Center(child: Icon(Icons.insert_drive_file, size: 30)),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => controller.removeFile(entry.key),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  GestureDetector(
                    onTap: () => controller.pickFiles(),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, style: BorderStyle.none),
                      ),
                      child: DottedBorder(
                        color: AppColors.primary,
                        strokeWidth: 1,
                        dashPattern: const [4, 4],
                        borderType: BorderType.rRect,
                        radius: const Radius.circular(12),
                        child: const Center(child: Icon(Icons.add, color: AppColors.primary)),
                      ),
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isSubmitting.value ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: controller.isSubmitting.value 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('submit_ticket'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.cardBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final success = await controller.createTicket(
        subject: _subjectController.text,
        category: _selectedCategory,
        priority: _selectedPriority,
        message: _messageController.text,
      );
      if (success) {
        Get.back();
        Get.snackbar(
          'success'.tr, 
          'ticket_created_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }
}

// Add DottedBorder if not available, or implement manually
class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final BorderType borderType;
  final Radius radius;

  const DottedBorder({
    super.key,
    required this.child,
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.dashPattern = const [6, 4],
    this.borderType = BorderType.rect,
    this.radius = Radius.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedPainter(color, strokeWidth, dashPattern, borderType, radius),
      child: child,
    );
  }
}

enum BorderType { rect, rRect, circle, oval }

class _DottedPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final BorderType borderType;
  final Radius radius;

  _DottedPainter(this.color, this.strokeWidth, this.dashPattern, this.borderType, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path();
    if (borderType == BorderType.rRect) {
      path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius));
    } else {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final double dashWidth = dashPattern[0];
    final double dashSpace = dashPattern[1];
    
    Path dashPath = Path();
    for (PathMetric measure in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < measure.length) {
        double len = draw ? dashWidth : dashSpace;
        if (draw) {
          dashPath.addPath(measure.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

