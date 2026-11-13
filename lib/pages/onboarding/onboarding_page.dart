import 'package:material_ui/material_ui.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../utils/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../auth/auth_page.dart';
import '../main_screen.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, dynamic>> get _pages => [
    {
      'title': 'onboarding_title_1'.tr,
      'highlight': ['Connect', 'Community', 'কমিউনিটি', 'সংযুক্ত', 'Connettiti', 'Community'],
      'description': 'onboarding_desc_1'.tr,
      'icon': HugeIcons.strokeRoundedUserGroup,
    },
    {
      'title': 'onboarding_title_2'.tr,
      'highlight': ['Share', 'Instantly', 'মুহূর্ত', 'শেয়ার', 'Condividi', 'Istante'],
      'description': 'onboarding_desc_2'.tr,
      'icon': HugeIcons.strokeRoundedImage01,
    },
    {
      'title': 'onboarding_title_3'.tr,
      'highlight': ['Grow', 'Brand', 'ব্র্যান্ড', 'বৃদ্ধি', 'Cresci', 'Brand'],
      'description': 'onboarding_desc_3'.tr,
      'icon': HugeIcons.strokeRoundedChartHistogram,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _completeOnboarding() async {
    final storage = GetStorage();
    await storage.write('has_seen_onboarding', true);
    
    final authController = Get.find<AuthController>();
    if (authController.isAuthenticated.value) {
      Get.offAll(() => const MainScreen());
    } else {
      Get.offAll(() => const AuthPage());
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glow Effect
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        final String title = page['title'] ?? '';
                        final List<String> highlights = page['highlight'] ?? [];

                        final List<TextSpan> textSpans = [];
                        final words = title.split(' ');
                        for (var word in words) {
                          final cleanWord = word.replaceAll(
                            RegExp(r'[^\w\s]'),
                            '',
                          );
                          final isHighlight = highlights.contains(cleanWord);
                          textSpans.add(
                            TextSpan(
                              text: '$word ',
                              style: AppTextStyles.h1.copyWith(
                                fontSize: 32,
                                fontWeight: isHighlight
                                    ? FontWeight.w900
                                    : FontWeight.w300,
                                color: AppColors.textMain,
                              ),
                            ),
                          );
                        }

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            RichText(text: TextSpan(children: textSpans)),
                            const SizedBox(height: 40),
                            Expanded(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: HugeIcon(
                                    icon: page['icon'],
                                    color: AppColors.primary,
                                    size: 150,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              page['description'] ?? '',
                              textAlign: TextAlign.left,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'skip'.tr,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(_pages.length, (index) {
                          final bool isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        }),
                      ),
                      GestureDetector(
                        onTap: _nextPage,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: HugeIcon(
                            icon: isLast
                                ? HugeIcons.strokeRoundedLock
                                : HugeIcons.strokeRoundedArrowRight01,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
