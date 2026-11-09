



// To parse this JSON data, do
//
//     final registerResponse = registerResponseFromJson(jsonString);

import 'dart:convert';

RegisterResponse registerResponseFromJson(String str) => RegisterResponse.fromJson(json.decode(str));

String registerResponseToJson(RegisterResponse data) => json.encode(data.toJson());

class RegisterResponse {
  String? status;
  String? message;
  bool? isOtpAvailable;
  Data? data;

  RegisterResponse({
    this.status,
    this.message,
    this.isOtpAvailable,
    this.data,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) => RegisterResponse(
    status: json["status"],
    message: json["message"],
    isOtpAvailable: json["is_otp_available"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "is_otp_available": isOtpAvailable,
    "data": data?.toJson(),
  };
}

class Data {
  int? id;
  String? email;
  String? phone;
  String? password;
  String? firstName;
  String? lastName;
  String? username;
  dynamic referralCode;
  String? ipAddress;
  String? token;
  String? countryId;
  String? otp;
  DateTime? expiresAt;
  DateTime? createdAt;
  DateTime? updatedAt;

  Data({
    this.id,
    this.email,
    this.phone,
    this.password,
    this.firstName,
    this.lastName,
    this.username,
    this.referralCode,
    this.ipAddress,
    this.token,
    this.countryId,
    this.otp,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: json["id"],
    email: json["email"],
    phone: json["phone"],
    password: json["password"],
    firstName: json["first_name"],
    lastName: json["last_name"],
    username: json["username"],
    referralCode: json["referral_code"],
    ipAddress: json["ip_address"],
    token: json["token"],
    countryId: json["country_id"],
    otp: json["otp"],
    expiresAt: json["expires_at"] == null ? null : DateTime.parse(json["expires_at"]),
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "email": email,
    "phone": phone,
    "password": password,
    "first_name": firstName,
    "last_name": lastName,
    "username": username,
    "referral_code": referralCode,
    "ip_address": ipAddress,
    "token": token,
    "country_id": countryId,
    "otp": otp,
    "expires_at": expiresAt?.toIso8601String(),
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

