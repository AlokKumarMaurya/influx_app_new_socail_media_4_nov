import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../utils/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../config/app_config.dart';
import '../../widgets/app_drop_down.dart';
import 'forgot_password_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  late TabController _tabController;
  bool _isPasswordVisible = false;

  final _loginController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerFirstNameController = TextEditingController();
  final _registerLastNameController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  final _registerMobileNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginController.dispose();
    _loginPasswordController.dispose();
    _registerFirstNameController.dispose();
    _registerLastNameController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  _buildTabSwitcher(),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildLoginForm(), _buildRegisterForm()],
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Image.asset(AppConfig.logoPath, height: 80),
            const SizedBox(height: 16),
            Text(
              AppConfig.appName,
              style: AppTextStyles.h1.copyWith(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome to your social world',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.textMain.withValues(alpha: 0.05)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        padding: const EdgeInsets.all(2),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: 'login'.tr),
          Tab(text: 'register'.tr),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _loginController,
          hint: 'email_or_username'.tr,
          icon: HugeIcons.strokeRoundedUser,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _loginPasswordController,
          hint: 'password'.tr,
          icon: HugeIcons.strokeRoundedLock,
          isPassword: true,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Get.to(() => const ForgotPasswordPage()),
            child: Text(
              'forgotPassword'.tr,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButton('login'.tr, () {
          _authController.login(
            _loginController.text,
            _loginPasswordController.text,
          );
        }),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _registerFirstNameController,
                hint: 'First Name'.tr,
                icon: HugeIcons.strokeRoundedUser,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _registerLastNameController,
                hint: 'Last Name'.tr,
                icon: HugeIcons.strokeRoundedUser,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          validator: (value) =>
              validateHmeUserName(value != null ? "$value@hme" : null),
          controller: _registerUsernameController,
          hint: 'username'.tr,
          icon: HugeIcons.strokeRoundedUserCircle,
          suffixText: '@hme',
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(
                text: newValue.text.toLowerCase(),
                selection: newValue.selection,
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppDropDown(
                items: (_authController.countries.value?.data ?? [])
                    .map((e) => e.phoneCode ?? "")
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _authController.selectedCountryId = _authController
                        .countries
                        .value
                        ?.data!
                        .firstWhere((element) => element.phoneCode == value)
                        .id
                        .toString();
                    // ref
                    //     .read(socialMediaControllerProvider.notifier)
                    //     .setPlatformType(value);
                  }
                },
                hintText: "+91",
                isFilled: true,
                fillColor: AppColors.white,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "countries field is required";
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _registerMobileNumberController,
                hint: 'Phone Number'.tr,
                icon: HugeIcons.strokeRoundedSmartPhone01,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _registerEmailController,
          hint: 'email'.tr,
          icon: HugeIcons.strokeRoundedMail01,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _registerPasswordController,
          hint: 'password'.tr,
          icon: HugeIcons.strokeRoundedLock,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _registerConfirmPasswordController,
          hint: 'confirmPassword'.tr,
          icon: HugeIcons.strokeRoundedLock,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        _buildActionButton('register'.tr, () {
          _authController.register(
            countryId: _authController.selectedCountryId ?? '',
            phone: _registerMobileNumberController.text,
            firstName: _registerFirstNameController.text,
            lastName: _registerLastNameController.text,
            username: "${_registerUsernameController.text}@hme",
            email: _registerEmailController.text,
            password: _registerPasswordController.text,
            passwordConfirmation: _registerConfirmPasswordController.text,
          );
        }),
      ],
    );
  }

  String? validateHmeUserName(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }

    if (value.contains(' ')) {
      return 'Spaces are not allowed';
    }

    if (value != value.toLowerCase()) {
      return 'Only lowercase letters are allowed';
    }

    if (!value.endsWith('@hme')) {
      return 'Username must end with @hme';
    }

    if (!RegExp(r'^[a-z0-9]+@hme$').hasMatch(value)) {
      return 'Only lowercase letters and numbers are allowed before @hme';
    }

    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required dynamic icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    String? suffixText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.textMain.withValues(alpha: 0.05)),
      ),
      child: TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: TextStyle(color: AppColors.textMain),
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: HugeIcon(icon: icon, color: AppColors.primary, size: 22),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: HugeIcon(
                    icon: _isPasswordVisible
                        ? HugeIcons.strokeRoundedView
                        : HugeIcons.strokeRoundedViewOff,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : suffixText != null
              ? Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(suffixText),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: Obx(
        () => ElevatedButton(
          onPressed: _authController.isLoading.value ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: _authController.isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
