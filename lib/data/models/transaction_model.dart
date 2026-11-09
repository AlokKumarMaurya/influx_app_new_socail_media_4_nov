class TransactionModel {
  final int id;
  final String uuid;
  final String gateway;
  final String amount;
  final String formattedAmount;
  final String? referenceId;
  final String status;
  final String date;
  final String time;
  final String relative;

  TransactionModel({
    required this.id,
    required this.uuid,
    required this.gateway,
    required this.amount,
    required this.formattedAmount,
    this.referenceId,
    required this.status,
    required this.date,
    required this.time,
    required this.relative,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      gateway: json['gateway'] ?? '',
      amount: json['amount']?.toString() ?? '0.00',
      formattedAmount: json['formatted_amount'] ?? '0.00',
      referenceId: json['reference_id'],
      status: json['status'] ?? 'pending',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      relative: json['relative'] ?? '',
    );
  }
}
