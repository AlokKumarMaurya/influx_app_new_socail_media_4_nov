import 'user_model.dart';

class ReactionModel {
  final int id;
  final String type;
  final UserModel user;
  final String createdAt;

  ReactionModel({
    required this.id,
    required this.type,
    required this.user,
    required this.createdAt,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      id: json['id'],
      type: json['type'],
      user: UserModel.fromJson(json['user']),
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'user': user.toJson(),
      'created_at': createdAt,
    };
  }
}
