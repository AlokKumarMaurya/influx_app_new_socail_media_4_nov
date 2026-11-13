import 'dart:io';
import 'package:flutter/src/material/app.dart';
import 'package:material_ui/material_ui.dart' hide ThemeMode;
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../controllers/wallet_controller.dart';
import '../../data/providers/api_client.dart';
import '../../pages/wallet/payment_webview_page.dart';
import '../../utils/app_theme.dart';

class DepositSheet extends StatefulWidget {
  const DepositSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DepositSheet(),
    );
  }

  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoadingConfig = true;
  bool _isSubmitting = false;

  bool _stripeEnabled = false;
  bool _paypalEnabled = false;
  bool _paystackEnabled = false;
  bool _razorpayEnabled = false;
  bool _offlineEnabled = false;

  String _stripePublicKey = '';
  String _razorpayKeyId = '';
  String _offlineInstructions = '';
  String _currencySymbol = '\$';
  String _currencyCode = 'USD';

  String _selectedGateway = 'stripe';
  File? _receiptImage;

  Razorpay? _razorpay;
  int? _pendingRazorpayTrxId;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _fetchAppConfig();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _noteController.dispose();
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> _fetchAppConfig() async {
    try {
      final apiClient = Get.find<ApiClient>();
      final response = await apiClient.dio.get('/app-config');
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _stripeEnabled = data['stripe_status'] ?? false;
          _paypalEnabled = data['paypal_status'] ?? false;
          _paystackEnabled = data['paystack_status'] ?? false;
          _razorpayEnabled = data['razorpay_status'] ?? false;
          _offlineEnabled = data['offline_payment_status'] ?? false;

          _stripePublicKey = data['stripe_public_key'] ?? '';
          _razorpayKeyId = data['razorpay_key_id'] ?? '';
          _offlineInstructions = data['offline_payment_instruction'] ?? '';
          _currencySymbol = data['currency_symbol'] ?? '\$';
          _currencyCode = data['currency_code'] ?? 'USD';

          if (_stripeEnabled) {
            _selectedGateway = 'stripe';
          } else if (_paypalEnabled) {
            _selectedGateway = 'paypal';
          } else if (_paystackEnabled) {
            _selectedGateway = 'paystack';
          } else if (_razorpayEnabled) {
            _selectedGateway = 'razorpay';
          } else if (_offlineEnabled) {
            _selectedGateway = 'offline';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading deposit config: $e');
    } finally {
      if (mounted) setState(() => _isLoadingConfig = false);
    }
  }

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _receiptImage = File(picked.path);
      });
    }
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    if (_pendingRazorpayTrxId == null) return;
    final walletCtrl = Get.find<WalletController>();
    await walletCtrl.verifyDeposit(
      transactionId: _pendingRazorpayTrxId,
      gateway: 'razorpay',
      razorpayPaymentId: response.paymentId,
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    Get.snackbar(
      'payment_error'.tr,
      '${'payment_failed'.tr}: ${response.message}',
      backgroundColor: AppColors.error.withValues(alpha: 0.1),
      colorText: AppColors.error,
    );
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet selected: ${response.walletName}');
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      Get.snackbar(
        'invalid_amount'.tr,
        'enter_valid_deposit_amount'.tr,
        backgroundColor: AppColors.error.withValues(alpha: 0.1),
        colorText: AppColors.error,
      );
      return;
    }

    if (_selectedGateway == 'offline') {
      if (_receiptImage == null) {
        Get.snackbar(
          'receipt_required'.tr,
          'upload_deposit_receipt_prompt'.tr,
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          colorText: AppColors.error,
        );
        return;
      }

      setState(() => _isSubmitting = true);
      final walletCtrl = Get.find<WalletController>();
      final success = await walletCtrl.submitOfflineDeposit(
        amount: amount,
        referenceId: _refController.text.trim(),
        receiptImage: _receiptImage!,
        note: _noteController.text.trim(),
      );
      setState(() => _isSubmitting = false);
      if (success && mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _isSubmitting = true);
    final walletCtrl = Get.find<WalletController>();
    final Map<String, dynamic>? payload;
    try {
      payload = await walletCtrl.initiateOnlineDeposit(
        gateway: _selectedGateway,
        amount: amount,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (payload == null) return;

    final trxId = payload['transaction_id'];

      final checkoutUrl = payload['checkout_url'];
      final clientSecret = payload['client_secret'];
      final pubKey = payload['publishable_key'] ?? _stripePublicKey;

      if (_selectedGateway == 'stripe' && checkoutUrl == null && clientSecret != null && clientSecret.toString().isNotEmpty) {
        if (pubKey != null && pubKey.toString().isNotEmpty) {
          Stripe.publishableKey = pubKey.toString();
          try {
            await Stripe.instance.applySettings();
          } catch (_) {}
        }

        try {
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: 'InFluX Community',
              style: ThemeMode.light as ThemeMode?,
            ),
          );
          await Stripe.instance.presentPaymentSheet();

          final verified = await walletCtrl.verifyDeposit(
            transactionId: trxId,
            gateway: 'stripe',
            paymentIntentId: clientSecret,
          );
          if (verified && mounted) Navigator.of(context).pop();
          return;
        } catch (e) {
          debugPrint('Stripe native sheet error: $e');
        }
      }

      if (_selectedGateway == 'razorpay') {
        final keyId = payload['key_id'] ?? _razorpayKeyId;
        _pendingRazorpayTrxId = trxId;

        final options = {
          'key': keyId,
          'amount': payload['amount_in_subunits'] ?? (amount * 100).toInt(),
          'name': 'InFluX Wallet Top Up',
          'description': 'Deposit to wallet balance',
          'prefill': {
            'contact': payload['user_phone'] ?? '',
            'email': payload['user_email'] ?? '',
          },
        };

        try {
          _razorpay?.open(options);
        } catch (e) {
          debugPrint('Error opening Razorpay: $e');
        }
        return;
      }

      if (checkoutUrl != null && checkoutUrl.toString().isNotEmpty) {
        if (!mounted) return;
        final completed = await PaymentWebViewPage.open(
          context,
          initialUrl: checkoutUrl.toString(),
          title: '${_selectedGateway.toUpperCase()} Deposit',
        );

        if (completed == true) {
          await walletCtrl.verifyDeposit(
            transactionId: trxId,
            gateway: _selectedGateway,
          );
          if (mounted) Navigator.of(context).pop();
        }
      } else {
        Get.snackbar(
          'checkout_error'.tr,
          'unable_to_initialize_payment'.tr,
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          colorText: AppColors.error,
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final borderColor = AppColors.textSecondary.withValues(alpha: 0.2);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedAddCircle,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('add_money'.tr, style: AppTextStyles.h3),
                        Text('top_up_wallet_balance'.tr, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            if (_isLoadingConfig)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount Input Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${'enter_amount'.tr} ($_currencyCode)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: AppTextStyles.h2.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  prefixText: '$_currencySymbol ',
                                  prefixStyle: AppTextStyles.h2.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  hintText: '0.00',
                                  hintStyle: AppTextStyles.h2.copyWith(
                                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'enter_amount'.tr;
                                  final num = double.tryParse(val.trim());
                                  if (num == null || num <= 0) return 'invalid_amount'.tr;
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text('select_payment_gateway'.tr.toUpperCase(), style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 10),

                        // Gateway Cards
                        if (_stripeEnabled) _buildGatewayOption('stripe', 'Stripe', HugeIcons.strokeRoundedCreditCard, Colors.indigo),
                        if (_paypalEnabled) _buildGatewayOption('paypal', 'PayPal', HugeIcons.strokeRoundedWallet01, Colors.blue),
                        if (_paystackEnabled) _buildGatewayOption('paystack', 'Paystack', HugeIcons.strokeRoundedLaptop, Colors.teal),
                        if (_razorpayEnabled) _buildGatewayOption('razorpay', 'Razorpay', HugeIcons.strokeRoundedTag01, Colors.orange),
                        if (_offlineEnabled) _buildGatewayOption('offline', 'offline_bank_transfer'.tr, HugeIcons.strokeRoundedBank, Colors.purple),

                        // Offline Payment Instructions & Proof Upload
                        if (_selectedGateway == 'offline') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, color: AppColors.primary, size: 18),
                                    const SizedBox(width: 8),
                                    Text('bank_transfer_instructions'.tr, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SelectableText(_offlineInstructions, style: AppTextStyles.bodySmall),
                                const SizedBox(height: 16),

                                Text('${'transaction_ref_id'.tr} *', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _refController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. TXN987654321',
                                    filled: true,
                                    fillColor: AppColors.cardBg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'enter_reference_id'.tr : null,
                                ),
                                const SizedBox(height: 12),

                                Text('${'receipt_proof_screenshot'.tr} *', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: _pickReceiptImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: _receiptImage != null
                                        ? Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(_receiptImage!, width: 44, height: 44, fit: BoxFit.cover),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _receiptImage!.path.split('/').last,
                                                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: AppColors.textSecondary, size: 20),
                                              const SizedBox(width: 8),
                                              Text('tap_to_upload_receipt'.tr, style: AppTextStyles.bodySmall),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    _selectedGateway == 'offline' ? 'submit_deposit_request'.tr : 'continue_to_payment'.tr,
                                    style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayOption(String value, String label, dynamic iconData, Color accentColor) {
    final isSelected = _selectedGateway == value;
    final borderColor = AppColors.textSecondary.withValues(alpha: 0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedGateway = value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: _selectedGateway,
                onChanged: (v) {
                  if (v != null) setState(() => _selectedGateway = v);
                },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(icon: iconData, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              ),
              if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
