class TicketModel {
  final int id;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final String lastReplyAt;
  final String createdAt;

  TicketModel({
    required this.id,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.lastReplyAt,
    required this.createdAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      subject: json['subject'],
      category: json['category'] ?? '',
      priority: json['priority'] ?? '',
      status: json['status'] ?? 'Open',
      lastReplyAt: json['last_reply_at'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class TicketMessageModel {
  final int id;
  final int userId;
  final String userName;
  final String? userAvatar;
  final bool isAdmin;
  final String message;
  final List<String> attachments;
  final String createdAt;

  TicketMessageModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.isAdmin,
    required this.message,
    required this.attachments,
    required this.createdAt,
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) {
    return TicketMessageModel(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'User',
      userAvatar: json['user_avatar'],
      isAdmin: json['is_admin'] ?? false,
      message: json['message'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: json['created_at'] ?? '',
    );
  }
}
