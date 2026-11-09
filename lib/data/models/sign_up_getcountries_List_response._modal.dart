// To parse this JSON data, do
//
//     final getCountriesListResponseModal = getCountriesListResponseModalFromJson(jsonString);

import 'dart:convert';

GetCountriesListResponseModal getCountriesListResponseModalFromJson(
  String str,
) => GetCountriesListResponseModal.fromJson(json.decode(str));

String getCountriesListResponseModalToJson(
  GetCountriesListResponseModal data,
) => json.encode(data.toJson());

class GetCountriesListResponseModal {
  final bool? status;
  final String? message;
  List<GetCountriesListResponseModalDatum>? data;

  GetCountriesListResponseModal({this.status, this.message, this.data});

  GetCountriesListResponseModal copyWith({
    bool? status,
    String? message,
    List<GetCountriesListResponseModalDatum>? data,
  }) => GetCountriesListResponseModal(
    status: status ?? this.status,
    message: message ?? this.message,
    data: data ?? this.data,
  );

  factory GetCountriesListResponseModal.fromJson(Map<String, dynamic> json) =>
      GetCountriesListResponseModal(
        data: json["data"] == null
            ? []
            : List<GetCountriesListResponseModalDatum>.from(
                json["data"]!.map(
                  (x) => GetCountriesListResponseModalDatum.fromJson(x),
                ),
              ),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data == null
        ? []
        : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class GetCountriesListResponseModalDatum {
  final int? id;
  final String? uuid;
  final String? name;
  final String? iso2;
  final String? iso3;
  final String? phoneCode;
  final int? mobileMinLength;
  final int? mobileMaxLength;
  final bool? status;
  final dynamic deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GetCountriesListResponseModalDatum({
    this.id,
    this.uuid,
    this.name,
    this.iso2,
    this.iso3,
    this.phoneCode,
    this.mobileMinLength,
    this.mobileMaxLength,
    this.status,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  GetCountriesListResponseModalDatum copyWith({
    int? id,
    String? uuid,
    String? name,
    String? iso2,
    String? iso3,
    String? phoneCode,
    int? mobileMinLength,
    int? mobileMaxLength,
    bool? status,
    dynamic deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => GetCountriesListResponseModalDatum(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    iso2: iso2 ?? this.iso2,
    iso3: iso3 ?? this.iso3,
    phoneCode: phoneCode ?? this.phoneCode,
    mobileMinLength: mobileMinLength ?? this.mobileMinLength,
    mobileMaxLength: mobileMaxLength ?? this.mobileMaxLength,
    status: status ?? this.status,
    deletedAt: deletedAt ?? this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory GetCountriesListResponseModalDatum.fromJson(
    Map<String, dynamic> json,
  ) => GetCountriesListResponseModalDatum(
    id: json["id"],
    uuid: json["uuid"],
    name: json["name"],
    iso2: json["iso2"],
    iso3: json["iso3"],
    phoneCode: json["phone_code"],
    mobileMinLength: json["mobile_min_length"],
    mobileMaxLength: json["mobile_max_length"],
    status: json["status"],
    deletedAt: json["deleted_at"],
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uuid": uuid,
    "name": name,
    "iso2": iso2,
    "iso3": iso3,
    "phone_code": phoneCode,
    "mobile_min_length": mobileMinLength,
    "mobile_max_length": mobileMaxLength,
    "status": status,
    "deleted_at": deletedAt,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}
