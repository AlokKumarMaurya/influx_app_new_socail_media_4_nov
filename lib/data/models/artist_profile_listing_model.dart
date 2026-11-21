class ArtistFilterOption {
  final String id;
  final String name;

  const ArtistFilterOption({required this.id, required this.name});

  factory ArtistFilterOption.fromJson(Map<String, dynamic> json) {
    return ArtistFilterOption(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class ArtistProfileListingModel {
  final int artistId;
  final int userId;
  final String artistName;
  final String username;
  final String? profileImage;
  final String? coverImage;
  final ArtistFilterOption category;
  final ArtistFilterOption industry;
  final String gender;
  final String experience;
  final int popularMoviesCount;
  final double rating;
  final bool isVerified;
  final int followersCount;
  final String profileVisibility;
  final String? phoneNumber;

  const ArtistProfileListingModel({
    required this.artistId,
    required this.userId,
    required this.artistName,
    required this.username,
    this.profileImage,
    this.coverImage,
    required this.category,
    required this.industry,
    required this.gender,
    required this.experience,
    required this.popularMoviesCount,
    required this.rating,
    required this.isVerified,
    required this.followersCount,
    required this.profileVisibility,
    this.phoneNumber,
  });

  factory ArtistProfileListingModel.fromJson(Map<String, dynamic> json) {
    return ArtistProfileListingModel(
      artistId: _toInt(json['artistId']),
      userId: _toInt(json['userId']),
      artistName: (json['artistName'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      profileImage: json['profileImage']?.toString(),
      coverImage: json['coverImage']?.toString(),
      category: ArtistFilterOption.fromJson(
        Map<String, dynamic>.from(json['category'] ?? const {}),
      ),
      industry: ArtistFilterOption.fromJson(
        Map<String, dynamic>.from(json['industry'] ?? const {}),
      ),
      gender: (json['gender'] ?? '').toString(),
      experience: (json['experience'] ?? '').toString(),
      popularMoviesCount: _toInt(json['popularMoviesCount']),
      rating: _toDouble(json['rating']),
      isVerified: json['isVerified'] == true,
      followersCount: _toInt(json['followersCount']),
      profileVisibility: (json['profileVisibility'] ?? 'PUBLIC').toString(),
      phoneNumber: json['phoneNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'artistId': artistId,
    'userId': userId,
    'artistName': artistName,
    'username': username,
    'profileImage': profileImage,
    'coverImage': coverImage,
    'category': category.toJson(),
    'industry': industry.toJson(),
    'gender': gender,
    'experience': experience,
    'popularMoviesCount': popularMoviesCount,
    'rating': rating,
    'isVerified': isVerified,
    'followersCount': followersCount,
    'profileVisibility': profileVisibility,
    'phoneNumber': phoneNumber,
  };
}

class ArtistListingPagination {
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const ArtistListingPagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory ArtistListingPagination.fromJson(Map<String, dynamic> json) {
    return ArtistListingPagination(
      currentPage: _toInt(json['currentPage'], fallback: 1),
      pageSize: _toInt(json['pageSize'], fallback: 10),
      totalRecords: _toInt(json['totalRecords']),
      totalPages: _toInt(json['totalPages'], fallback: 1),
      hasNext: json['hasNext'] == true,
      hasPrevious: json['hasPrevious'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentPage': currentPage,
    'pageSize': pageSize,
    'totalRecords': totalRecords,
    'totalPages': totalPages,
    'hasNext': hasNext,
    'hasPrevious': hasPrevious,
  };
}

class ArtistProfileListingResponse {
  final List<ArtistProfileListingModel> artists;
  final ArtistListingPagination pagination;

  const ArtistProfileListingResponse({
    required this.artists,
    required this.pagination,
  });

  factory ArtistProfileListingResponse.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] ?? json);
    final pagination = Map<String, dynamic>.from(
      data['pagination'] ?? const {},
    );
    final artists = (data['artists'] as List? ?? const [])
        .map((item) => ArtistProfileListingModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();

    return ArtistProfileListingResponse(
      artists: artists,
      pagination: ArtistListingPagination.fromJson(pagination),
    );
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
