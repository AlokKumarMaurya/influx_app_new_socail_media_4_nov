import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:get/get.dart';
import '../data/providers/api_client.dart';
import '../data/models/wallet_log_model.dart';
import 'package:material_ui/material_ui.dart';
import '../utils/app_theme.dart';
import '../data/models/transaction_model.dart';

class WalletController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  final RxBool isLoadingStats = true.obs;
  final RxBool isLoadingLogs = true.obs;
  final RxBool isLoadingTransactions = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isLoadingMoreTransactions = false.obs;

  final RxString currencySymbol = '\$'.obs;

  final RxDouble balance = 0.0.obs;
  final RxString formattedBalance = '0.00'.obs;
  final RxString totalCredits = '0.00'.obs;
  final RxString totalDebits = '0.00'.obs;
  final RxString monthCredits = '0.00'.obs;
  final RxString monthDebits = '0.00'.obs;

  final RxList<WalletLogModel> walletLogs = <WalletLogModel>[].obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;

  int _currentPage = 1;
  bool _hasMorePages = true;

  int _trxPage = 1;
  bool _hasMoreTrx = true;

  String _currentFilter = ''; // 'credit', 'debit', or empty string

  @override
  void onInit() {
    super.onInit();
    loadWallet();
  }

  Future<void> loadWallet() async {
    await fetchStats();
    await fetchLogs(refresh: true);
    await fetchTransactions(refresh: true);
  }

  void setFilter(String filter) {
    if (_currentFilter == filter) {
      _currentFilter = ''; // toggle off
    } else {
      _currentFilter = filter;
    }
    fetchLogs(refresh: true);
  }

  String get currentFilter => _currentFilter;

  Future<void> fetchStats() async {
    isLoadingStats.value = true;
    try {
      final response = await _apiClient.dio.get('/wallet');
      if (response.data != null && response.data['success'] == true) {
        currencySymbol.value = response.data['currency_symbol'] ?? '\$';
        balance.value =
            double.tryParse(response.data['balance'].toString()) ?? 0.0;
        formattedBalance.value = response.data['formatted_balance'] ?? '0.00';

        final stats = response.data['stats'];
        if (stats != null) {
          totalCredits.value = stats['total_credits']?.toString() ?? '0.00';
          totalDebits.value = stats['total_debits']?.toString() ?? '0.00';
          monthCredits.value = stats['month_credits']?.toString() ?? '0.00';
          monthDebits.value = stats['month_debits']?.toString() ?? '0.00';
        }
      }
    } catch (e) {
      debugPrint('Error fetching wallet stats: $e');
    } finally {
      isLoadingStats.value = false;
    }
  }

  Future<void> fetchLogs({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMorePages = true;
      walletLogs.clear();
      isLoadingLogs.value = true;
    } else {
      if (!_hasMorePages || isLoadingMore.value) return;
      isLoadingMore.value = true;
    }

    try {
      String path = '/wallet/logs?page=$_currentPage';
      if (_currentFilter.isNotEmpty) {
        path += '&type=$_currentFilter';
      }

      final response = await _apiClient.dio.get(path);
      if (response.data != null && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final logs = data.map((x) => WalletLogModel.fromJson(x)).toList();

        if (refresh) {
          walletLogs.assignAll(logs);
        } else {
          walletLogs.addAll(logs);
        }

        _currentPage++;
        _hasMorePages = response.data['has_more'] ?? false;
      }
    } catch (e) {
      debugPrint('Error fetching wallet logs: $e');
    } finally {
      isLoadingLogs.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchTransactions({bool refresh = false}) async {
    if (refresh) {
      _trxPage = 1;
      _hasMoreTrx = true;
      transactions.clear();
      isLoadingTransactions.value = true;
    } else {
      if (!_hasMoreTrx || isLoadingMoreTransactions.value) return;
      isLoadingMoreTransactions.value = true;
    }

    try {
      final response = await _apiClient.dio.get(
        '/wallet/transactions?page=$_trxPage',
      );
      if (response.data != null && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final items = data.map((x) => TransactionModel.fromJson(x)).toList();

        if (refresh) {
          transactions.assignAll(items);
        } else {
          transactions.addAll(items);
        }

        _trxPage++;
        _hasMoreTrx = response.data['has_more'] ?? false;
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    } finally {
      isLoadingTransactions.value = false;
      isLoadingMoreTransactions.value = false;
    }
  }

  Future<bool> submitOfflineDeposit({
    required double amount,
    required String referenceId,
    required File receiptImage,
    String? note,
  }) async {
    try {
      final formData = dio_pkg.FormData.fromMap({
        'amount': amount,
        'reference_id': referenceId,
        'note': note ?? '',
        'receipt_image': await dio_pkg.MultipartFile.fromFile(
          receiptImage.path,
          filename: receiptImage.path.split('/').last,
        ),
      });

      final response = await _apiClient.dio.post(
        '/wallet/deposit/offline',
        data: formData,
      );
      if (response.data != null && response.data['success'] == true) {
        Get.snackbar(
          'Deposit Submitted',
          'Your offline payment deposit has been submitted and is pending verification.',
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          colorText: AppColors.success,
        );
        fetchTransactions(refresh: true);
        return true;
      } else {
        Get.snackbar(
          'Submission Failed',
          response.data?['message'] ?? 'Unable to submit deposit',
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          colorText: AppColors.error,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit deposit: $e',
        backgroundColor: AppColors.error.withValues(alpha: 0.1),
        colorText: AppColors.error,
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> initiateOnlineDeposit({
    required String gateway,
    required double amount,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/wallet/deposit/initiate',
        data: {'gateway': gateway, 'amount': amount},
      );

      if (response.data != null && response.data['success'] == true) {
        return response.data['data'];
      } else {
        Get.snackbar(
          'Initiation Failed',
          response.data?['message'] ?? 'Unable to initiate deposit',
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          colorText: AppColors.error,
        );
      }
    } on dio_pkg.DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Failed to initiate deposit';
      Get.snackbar(
        'Initiation Error',
        message.toString(),
        backgroundColor: AppColors.error.withValues(alpha: 0.1),
        colorText: AppColors.error,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to initiate deposit: $e',
        backgroundColor: AppColors.error.withValues(alpha: 0.1),
        colorText: AppColors.error,
      );
    }
    return null;
  }

  Future<bool> verifyDeposit({
    required dynamic transactionId,
    required String gateway,
    String? paymentIntentId,
    String? paystackReference,
    String? razorpayPaymentId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/wallet/deposit/verify',
        data: {
          'transaction_id': transactionId,
          'gateway': gateway,
          'payment_intent_id': paymentIntentId,
          'paystack_reference': paystackReference,
          'razorpay_payment_id': razorpayPaymentId,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        Get.snackbar(
          'Deposit Successful',
          'Money added to your wallet successfully!',
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          colorText: AppColors.success,
        );
        await loadWallet();
        return true;
      } else {
        Get.snackbar(
          'Verification Failed',
          response.data?['message'] ?? 'Unable to verify payment',
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          colorText: AppColors.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Verification error: $e',
        backgroundColor: AppColors.error.withValues(alpha: 0.1),
        colorText: AppColors.error,
      );
    }
    return false;
  }

  bool get hasMore => _hasMorePages;
  bool get hasMoreTrx => _hasMoreTrx;
}
