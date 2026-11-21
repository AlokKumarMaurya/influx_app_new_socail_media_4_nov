import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/artist_profile_listing_model.dart';

/// Temporary local data source for the Artist Discovery screen.
///
/// Replace these static catalogues and demo records with the filters/listing
/// APIs in the follow-up backend integration PR. The UI already consumes the
/// same model shapes expected from those APIs.
class ArtistListingController extends GetxController {
  static const int pageSize = 10;

  static const List<ArtistFilterOption> categories = [
    ArtistFilterOption(id: '1', name: 'Actor'),
    ArtistFilterOption(id: '2', name: 'Model'),
    ArtistFilterOption(id: '3', name: 'Singer'),
    ArtistFilterOption(id: '4', name: 'Dancer'),
  ];

  static const List<ArtistFilterOption> industries = [
    ArtistFilterOption(id: '1', name: 'Bollywood'),
    ArtistFilterOption(id: '2', name: 'Tollywood'),
    ArtistFilterOption(id: '3', name: 'Hollywood'),
    ArtistFilterOption(id: '4', name: 'Television'),
  ];

  static const List<ArtistFilterOption> genders = [
    ArtistFilterOption(id: '1', name: 'Male'),
    ArtistFilterOption(id: '2', name: 'Female'),
    ArtistFilterOption(id: '3', name: 'Other'),
  ];

  static const List<ArtistFilterOption> experiences = [
    ArtistFilterOption(id: '1', name: 'Fresher'),
    ArtistFilterOption(id: '2', name: '1+ yrs'),
    ArtistFilterOption(id: '3', name: '3+ yrs'),
    ArtistFilterOption(id: '4', name: '5+ yrs'),
    ArtistFilterOption(id: '5', name: '10+ yrs'),
  ];

  static const List<ArtistFilterOption> sortOptions = [
    ArtistFilterOption(id: 'popularity', name: 'Popularity'),
    ArtistFilterOption(id: 'newest', name: 'Newest'),
    ArtistFilterOption(id: 'experience', name: 'Experience'),
    ArtistFilterOption(id: 'rating', name: 'Rating'),
  ];

  static final List<ArtistProfileListingModel> _demoArtists = [
    ArtistProfileListingModel(
      artistId: 101, userId: 501, artistName: 'Aarav Sharma',
      username: 'aarav_sharma', category: categories[0], industry: industries[0],
      gender: 'Male', experience: '5+ Yrs', popularMoviesCount: 12,
      rating: 5.0, isVerified: true, followersCount: 250000,
      profileVisibility: 'PUBLIC',
    ),
    ArtistProfileListingModel(
      artistId: 102, userId: 502, artistName: 'Mira Kapoor',
      username: 'mira_kapoor', category: categories[1], industry: industries[0],
      gender: 'Female', experience: '3+ Yrs', popularMoviesCount: 8,
      rating: 4.9, isVerified: true, followersCount: 185000,
      profileVisibility: 'PUBLIC',
    ),
    ArtistProfileListingModel(
      artistId: 103, userId: 503, artistName: 'Rohan Verma',
      username: 'rohan_verma', category: categories[0], industry: industries[1],
      gender: 'Male', experience: '10+ Yrs', popularMoviesCount: 24,
      rating: 4.8, isVerified: false, followersCount: 142000,
      profileVisibility: 'PUBLIC',
    ),
    ArtistProfileListingModel(
      artistId: 104, userId: 504, artistName: 'Ananya Rao',
      username: 'ananya_rao', category: categories[2], industry: industries[1],
      gender: 'Female', experience: '5+ Yrs', popularMoviesCount: 6,
      rating: 4.9, isVerified: true, followersCount: 128000,
      profileVisibility: 'PUBLIC',
    ),
    ArtistProfileListingModel(
      artistId: 105, userId: 505, artistName: 'Kabir Singh',
      username: 'kabir_singh', category: categories[3], industry: industries[3],
      gender: 'Male', experience: '3+ Yrs', popularMoviesCount: 4,
      rating: 4.7, isVerified: false, followersCount: 96000,
      profileVisibility: 'PUBLIC',
    ),
    ArtistProfileListingModel(
      artistId: 106, userId: 506, artistName: 'Sana Khan',
      username: 'sana_khan', category: categories[1], industry: industries[2],
      gender: 'Female', experience: '10+ Yrs', popularMoviesCount: 18,
      rating: 5.0, isVerified: true, followersCount: 310000,
      profileVisibility: 'PUBLIC',
    ),
    ArtistProfileListingModel(
      artistId: 107, userId: 507, artistName: 'Dev Malhotra',
      username: 'dev_malhotra', category: categories[0], industry: industries[0],
      gender: 'Male', experience: '1+ yrs', popularMoviesCount: 3,
      rating: 4.5, isVerified: false, followersCount: 54000,
      profileVisibility: 'PUBLIC',
    ),
    ArtistProfileListingModel(
      artistId: 108, userId: 508, artistName: 'Ishita Sen',
      username: 'ishita_sen', category: categories[2], industry: industries[3],
      gender: 'Female', experience: '5+ Yrs', popularMoviesCount: 9,
      rating: 4.8, isVerified: true, followersCount: 87000,
      profileVisibility: 'PUBLIC',
    ),
    ArtistProfileListingModel(
      artistId: 109, userId: 509, artistName: 'Neil Das',
      username: 'neil_das', category: categories[3], industry: industries[1],
      gender: 'Male', experience: 'Fresher', popularMoviesCount: 1,
      rating: 4.3, isVerified: false, followersCount: 12000,
      profileVisibility: 'PUBLIC',
    ),
    ArtistProfileListingModel(
      artistId: 110, userId: 510, artistName: 'Tara Joshi',
      username: 'tara_joshi', category: categories[1], industry: industries[0],
      gender: 'Female', experience: '3+ Yrs', popularMoviesCount: 7,
      rating: 4.7, isVerified: true, followersCount: 76000,
      profileVisibility: 'PUBLIC',
    ),
    ArtistProfileListingModel(
      artistId: 111, userId: 511, artistName: 'Arjun Nair',
      username: 'arjun_nair', category: categories[0], industry: industries[2],
      gender: 'Male', experience: '5+ Yrs', popularMoviesCount: 15,
      rating: 4.9, isVerified: true, followersCount: 205000,
      profileVisibility: 'PUBLIC',
    ),
    ArtistProfileListingModel(
      artistId: 112, userId: 512, artistName: 'Zoya Ali',
      username: 'zoya_ali', category: categories[1], industry: industries[1],
      gender: 'Female', experience: '1+ yrs', popularMoviesCount: 2,
      rating: 4.4, isVerified: false, followersCount: 33000,
      profileVisibility: 'PUBLIC',
    ),
  ];

  final artists = <ArtistProfileListingModel>[].obs;
  final visibleArtists = <ArtistProfileListingModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final searchController = TextEditingController();

  final selectedCategoryId = ''.obs;
  final selectedIndustryId = ''.obs;
  final selectedGenderId = ''.obs;
  final selectedExperienceId = ''.obs;
  final selectedSortBy = 'popularity'.obs;

  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final totalRecords = 0.obs;

  @override
  void onInit() {
    super.onInit();
    artists.assignAll(_demoArtists);
    applyFilters();
  }

  void applyFilters() {
    isLoading.value = true;
    final query = searchController.text.trim().toLowerCase();

    var result = _demoArtists.where((artist) {
      final matchesCategory = selectedCategoryId.value.isEmpty ||
          artist.category.id == selectedCategoryId.value;
      final matchesIndustry = selectedIndustryId.value.isEmpty ||
          artist.industry.id == selectedIndustryId.value;
      final matchesGender = selectedGenderId.value.isEmpty ||
          genders.firstWhere((item) => item.id == selectedGenderId.value).name ==
              artist.gender;
      final matchesExperience = selectedExperienceId.value.isEmpty ||
          _matchesExperience(artist.experience, selectedExperienceId.value);
      final matchesSearch = query.isEmpty ||
          artist.artistName.toLowerCase().contains(query) ||
          artist.username.toLowerCase().contains(query);
      return matchesCategory && matchesIndustry && matchesGender &&
          matchesExperience && matchesSearch;
    }).toList();

    switch (selectedSortBy.value) {
      case 'newest':
        result = result.reversed.toList();
        break;
      case 'experience':
        result.sort((a, b) => _experienceRank(b.experience)
            .compareTo(_experienceRank(a.experience)));
        break;
      case 'rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        result.sort((a, b) => b.followersCount.compareTo(a.followersCount));
    }

    currentPage.value = 1;
    totalRecords.value = result.length;
    totalPages.value = (result.length / pageSize).ceil().clamp(1, 999).toInt();
    visibleArtists.assignAll(result.take(pageSize));
    isLoading.value = false;
  }

  Future<void> loadNextPage() async {
    if (isLoadingMore.value || currentPage.value >= totalPages.value) return;
    isLoadingMore.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final filtered = _filteredAndSortedArtists();
    currentPage.value++;
    visibleArtists.addAll(
      filtered.skip((currentPage.value - 1) * pageSize).take(pageSize),
    );
    isLoadingMore.value = false;
  }

  List<ArtistProfileListingModel> _filteredAndSortedArtists() {
    final query = searchController.text.trim().toLowerCase();
    var result = _demoArtists.where((artist) {
      final matchesCategory = selectedCategoryId.value.isEmpty ||
          artist.category.id == selectedCategoryId.value;
      final matchesIndustry = selectedIndustryId.value.isEmpty ||
          artist.industry.id == selectedIndustryId.value;
      final matchesGender = selectedGenderId.value.isEmpty ||
          genders.firstWhere((item) => item.id == selectedGenderId.value).name ==
              artist.gender;
      final matchesExperience = selectedExperienceId.value.isEmpty ||
          _matchesExperience(artist.experience, selectedExperienceId.value);
      final matchesSearch = query.isEmpty ||
          artist.artistName.toLowerCase().contains(query) ||
          artist.username.toLowerCase().contains(query);
      return matchesCategory && matchesIndustry && matchesGender &&
          matchesExperience && matchesSearch;
    }).toList();

    if (selectedSortBy.value == 'newest') {
      result = result.reversed.toList();
    } else if (selectedSortBy.value == 'experience') {
      result.sort((a, b) => _experienceRank(b.experience)
          .compareTo(_experienceRank(a.experience)));
    } else if (selectedSortBy.value == 'rating') {
      result.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      result.sort((a, b) => b.followersCount.compareTo(a.followersCount));
    }
    return result;
  }

  bool _matchesExperience(String value, String id) {
    if (id == '1') return value.toLowerCase() == 'fresher';
    final requiredYears = switch (id) {
      '2' => 1,
      '3' => 3,
      '4' => 5,
      '5' => 10,
      _ => 0,
    };
    return _experienceRank(value) >= requiredYears;
  }

  int _experienceRank(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? 0 : int.tryParse(match.group(0)!) ?? 0;
  }

  void clearFilters() {
    selectedCategoryId.value = '';
    selectedIndustryId.value = '';
    selectedGenderId.value = '';
    selectedExperienceId.value = '';
    selectedSortBy.value = 'popularity';
    searchController.clear();
    applyFilters();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
