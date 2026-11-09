import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/wallet_controller.dart';
import '../../data/models/transaction_model.dart';
import '../../utils/app_theme.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WalletController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textMain,
            size: 24,
          ),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('deposit_history'.tr, style: AppTextStyles.h3),
            Text('track_wallet_funding_attempts'.tr,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingTransactions.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedDatabase,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text('no_transactions_found'.tr, style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text('no_deposits_made_yet'.tr,
                    style: AppTextStyles.bodyMedium),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchTransactions(refresh: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
                controller.fetchTransactions();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.transactions.length +
                  (controller.isLoadingMoreTransactions.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.transactions.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                return _TransactionItem(transaction: controller.transactions[index]);
              },
            ),
          ),
        );
      }),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final bool isPending = transaction.status == 'pending';
    final bool isRejected = transaction.status == 'rejected' || transaction.status == 'failed';
    
    Color statusColor = AppColors.success;
    String statusLabel = 'approved'.tr.toUpperCase();
    
    if (isPending) {
      statusColor = Colors.orange;
      statusLabel = 'pending_verification'.tr.toUpperCase();
    } else if (isRejected) {
      statusColor = AppColors.error;
      statusLabel = 'rejected'.tr.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getGatewayIcon(transaction.gateway),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${transaction.uuid.substring(0, 8).toUpperCase()}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      transaction.gateway.toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaction.formattedAmount,
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('reference'.tr.toUpperCase(), style: AppTextStyles.bodySmall.copyWith(fontSize: 9)),
                    Text(
                      transaction.referenceId ?? '---',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('date_and_time'.tr.toUpperCase(), style: AppTextStyles.bodySmall.copyWith(fontSize: 9)),
                    Text(
                      '${transaction.date} • ${transaction.time}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getGatewayIcon(String gateway) {
    switch (gateway.toLowerCase()) {
      case 'stripe':
        return Icons.credit_card;
      case 'paypal':
        return Icons.account_balance_wallet;
      case 'paystack':
        return Icons.payment;
      case 'razorpay':
        return Icons.layers;
      default:
        return Icons.help_outline;
    }
  }
}
