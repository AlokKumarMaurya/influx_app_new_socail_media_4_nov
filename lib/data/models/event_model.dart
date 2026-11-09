class EventModel {
  final int id;
  final String name;
  final String? description;
  final String type; // 'online' | 'in_person'
  final String? category;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final String? link;
  final String? coverImage;
  final String status; // 'upcoming' | 'ongoing' | 'completed' | 'cancelled'
  final bool isPaid;
  final double ticketPrice;
  final String currencySymbol;
  final bool canAccessMaterials;
  final int goingCount;
  final int interestedCount;
  final String? userStatus; // current user's RSVP
  final String? startDateFormatted;
  final String? startTimeFormatted;
  final String? endTimeFormatted;
  final EventHost? host;
  final List<EventAttendeeUser>? attendees;
  final List<EventMaterialModel>? materials;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.category,
    required this.startDate,
    this.endDate,
    this.location,
    this.link,
    this.coverImage,
    required this.status,
    this.isPaid = false,
    this.ticketPrice = 0.0,
    this.currencySymbol = '\$',
    this.canAccessMaterials = false,
    required this.goingCount,
    required this.interestedCount,
    this.userStatus,
    this.startDateFormatted,
    this.startTimeFormatted,
    this.endTimeFormatted,
    this.host,
    this.attendees,
    this.materials,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'in_person',
      category: json['category'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      location: json['location'],
      link: json['link'],
      coverImage: json['cover_image'],
      status: json['status'] ?? 'upcoming',
      isPaid: json['is_paid'] == true || json['is_paid'] == 1,
      ticketPrice: json['ticket_price'] != null ? (json['ticket_price'] as num).toDouble() : 0.0,
      currencySymbol: json['currency_symbol'] ?? '\$',
      canAccessMaterials: json['can_access_materials'] == true,
      goingCount: json['going_count'] ?? 0,
      interestedCount: json['interested_count'] ?? 0,
      userStatus: json['user_status'],
      startDateFormatted: json['start_date_formatted'],
      startTimeFormatted: json['start_time_formatted'],
      endTimeFormatted: json['end_time_formatted'],
      host: json['host'] != null ? EventHost.fromJson(json['host']) : null,
      attendees: json['attendees'] != null
          ? (json['attendees'] as List)
              .map((a) => EventAttendeeUser.fromJson(a))
              .toList()
          : null,
      materials: json['materials'] != null
          ? (json['materials'] as List)
              .map((m) => EventMaterialModel.fromJson(m))
              .toList()
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  EventModel copyWith({
    int? goingCount,
    int? interestedCount,
    String? userStatus,
    bool? canAccessMaterials,
  }) {
    return EventModel(
      id: id,
      name: name,
      description: description,
      type: type,
      category: category,
      startDate: startDate,
      endDate: endDate,
      location: location,
      link: link,
      coverImage: coverImage,
      status: status,
      isPaid: isPaid,
      ticketPrice: ticketPrice,
      currencySymbol: currencySymbol,
      canAccessMaterials: canAccessMaterials ?? this.canAccessMaterials,
      goingCount: goingCount ?? this.goingCount,
      interestedCount: interestedCount ?? this.interestedCount,
      userStatus: userStatus,
      startDateFormatted: startDateFormatted,
      startTimeFormatted: startTimeFormatted,
      endTimeFormatted: endTimeFormatted,
      host: host,
      attendees: attendees,
      materials: materials,
      createdAt: createdAt,
    );
  }
}

class EventMaterialModel {
  final int id;
  final String title;
  final String? fileName;
  final String? fileType;
  final int fileSize;
  final String? fileUrl;

  EventMaterialModel({
    required this.id,
    required this.title,
    this.fileName,
    this.fileType,
    required this.fileSize,
    this.fileUrl,
  });

  factory EventMaterialModel.fromJson(Map<String, dynamic> json) {
    return EventMaterialModel(
      id: json['id'],
      title: json['title'] ?? '',
      fileName: json['file_name'],
      fileType: json['file_type'],
      fileSize: json['file_size'] ?? 0,
      fileUrl: json['file_url'],
    );
  }
}

class EventHost {
  final int id;
  final String name;
  final String? username;
  final String? avatar;
  final String? profileType;

  EventHost({
    required this.id,
    required this.name,
    this.username,
    this.avatar,
    this.profileType,
  });

  factory EventHost.fromJson(Map<String, dynamic> json) {
    return EventHost(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'],
      avatar: json['avatar'],
      profileType: json['profile_type'] ?? 'user',
    );
  }
}

class EventAttendeeUser {
  final int id;
  final String name;
  final String? username;
  final String? avatar;
  final String status;

  EventAttendeeUser({
    required this.id,
    required this.name,
    this.username,
    this.avatar,
    required this.status,
  });

  factory EventAttendeeUser.fromJson(Map<String, dynamic> json) {
    return EventAttendeeUser(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'],
      avatar: json['avatar'],
      status: json['status'] ?? 'going',
    );
  }
}
