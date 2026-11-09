import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:influx_app/controllers/verification_code_controller.dart';
import 'package:influx_app/pages/auth/auth_page.dart';
import 'package:pinput/pinput.dart';

import '../../utils/app_theme.dart';
import '../../widgets/common/app_button.dart';

class SignUpRequestModal {
  String? countryId;
  String? firstName;
  String? lastName;
  String? phone;
  String? email;
  String? username;
  String? password;
  String? passwordConfirmation;
  bool isAutoFill;
  String? otp;

  SignUpRequestModal({
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.username,
    this.password,
    this.passwordConfirmation,
    this.isAutoFill = false,
    this.otp,
  });
}

class VerifyOtpArguments {
  final SignUpRequestModal signUpRequest;
  final String token;

  const VerifyOtpArguments({required this.signUpRequest, required this.token});
}

class VerificationCodeView extends StatefulWidget {
  final VerifyOtpArguments argument;

  const VerificationCodeView({super.key, required this.argument});

  @override
  State<VerificationCodeView> createState() => _VerificationCodeViewState();
}

class _VerificationCodeViewState extends State<VerificationCodeView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _verificationCodeController =
      TextEditingController();

  @override
  void initState() {
    if (widget.argument.signUpRequest.isAutoFill) {
      autoFillOtp();
    }
    super.initState();
  }

  Future<void> autoFillOtp() async {
    await Future.delayed(Duration(seconds: 1));
    _verificationCodeController.text = widget.argument.signUpRequest.otp!;
    Get.find<VerificationCodeController>().verifyCodeForSignUp(
      argument: widget.argument,
      otp: _verificationCodeController.text,
    );
  }

  @override
  void dispose() {
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VerificationCodeController>(
      init: VerificationCodeController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: InkWell(
                onTap: () => Get.back(),
                child: Icon(Icons.arrow_back),
              ),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          body: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),

                          SvgPicture.asset(
                            'assets/svg/verify_phone.svg',
                          ),

                          const SizedBox(height: 16),

                          Center(
                            child: Text(
                              "Verify your phone\nnumber",
                              textAlign: TextAlign.center,
                              style: boldTextStyle.copyWith(fontSize: 24),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Center(
                            child: Text(
                              "Enter code we've sent to your mobile\nnumber",
                              textAlign: TextAlign.center,
                              style: boldTextStyle.copyWith(fontSize: 14),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Pinput(
                            length: 6,
                            controller: _verificationCodeController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            validator: (value) =>
                            (value ?? "").length == 6
                                ? null
                                : "Enter valid OTP",
                            closeKeyboardWhenCompleted: true,
                            hapticFeedbackType:
                            HapticFeedbackType.lightImpact,
                          ),

                          const SizedBox(height: 24),

                          RichText(
                            text: TextSpan(
                              text: "Don't get the code? ",
                              style: GoogleFonts.raleway(
                                fontWeight: FontWeight.w400,
                                fontSize: 13,
                                color: Theme.of(context).canvasColor,
                              ),
                              children: [
                                TextSpan(
                                  text: "Resend It",
                                  style: GoogleFonts.raleway(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          AppButton(
                            text: "SUBMIT",
                            onTap: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                controller.verifyCodeForSignUp(
                                  argument: widget.argument,
                                  otp: _verificationCodeController.text,
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          InkWell(
                            onTap: () => Get.offAll(() => AuthPage()),
                            child: Center(
                              child: Text(
                                'Back to Login',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.raleway(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor:
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (controller.isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
