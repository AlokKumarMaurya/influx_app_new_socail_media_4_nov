class WalletLogModel {
  final int id;
  final String type;
  final String amount;
  final String formattedAmount;
  final String balanceBefore;
  final String balanceAfter;
  final String action;
  final String? description;
  final String? typeColor;
  final String? typeIcon;
  final String date;
  final String time;
  final String relative;

  WalletLogModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.formattedAmount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.action,
    this.description,
    this.typeColor,
    this.typeIcon,
    required this.date,
    required this.time,
    required this.relative,
  });

  factory WalletLogModel.fromJson(Map<String, dynamic> json) {
    return WalletLogModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      amount: json['amount']?.toString() ?? '0.00',
      formattedAmount: json['formatted_amount'] ?? '0.00',
      balanceBefore: json['balance_before']?.toString() ?? '0.00',
      balanceAfter: json['balance_after']?.toString() ?? '0.00',
      action: json['action'] ?? '',
      description: json['description'],
      typeColor: json['type_color'],
      typeIcon: json['type_icon'],
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      relative: json['relative'] ?? '',
    );
  }
}
