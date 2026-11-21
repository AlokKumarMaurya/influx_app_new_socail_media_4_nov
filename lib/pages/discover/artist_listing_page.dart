import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../../controllers/artist_listing_controller.dart';
import '../../data/models/artist_profile_listing_model.dart';
import '../../utils/app_theme.dart';
import '../user/profile_page.dart';

class ArtistListingPage extends StatefulWidget {
  const ArtistListingPage({super.key});

  static const Color _green = Color(0xFF4B8B2E);
  static const Color _purple = Color(0xFF4D3D80);
  static const Color _border = Color(0xFFD8E2D3);
  static const Color _muted = Color(0xFF737782);

  @override
  State<ArtistListingPage> createState() => _ArtistListingPageState();
}

class _ArtistListingPageState extends State<ArtistListingPage> {
  late final ArtistListingController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(ArtistListingController());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 260) {
      controller.loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 12,),
            _buildFilters(),
            SizedBox(height: 12,),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.visibleArtists.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.visibleArtists.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  onRefresh: () async => controller.applyFilters(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    itemCount: controller.visibleArtists.length +
                        (controller.isLoadingMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.visibleArtists.length) {
                        return const Padding(
                          padding: EdgeInsets.all(18),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _ArtistCard(
                        artist: controller.visibleArtists[index],
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 48,
      child: Obx(
        () => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          children: [
            _filterDropdown(
              label: 'Category',
              value: controller.selectedCategoryId.value,
              options: ArtistListingController.categories,
              onChanged: (value) {
                controller.selectedCategoryId.value = value ?? '';
                controller.applyFilters();
              },
            ),
            _filterDropdown(
              label: 'Industry',
              value: controller.selectedIndustryId.value,
              options: ArtistListingController.industries,
              onChanged: (value) {
                controller.selectedIndustryId.value = value ?? '';
                controller.applyFilters();
              },
            ),
            _filterDropdown(
              label: 'Gender',
              value: controller.selectedGenderId.value,
              options: ArtistListingController.genders,
              onChanged: (value) {
                controller.selectedGenderId.value = value ?? '';
                controller.applyFilters();
              },
            ),
            _filterDropdown(
              label: 'Experienced',
              value: controller.selectedExperienceId.value,
              options: ArtistListingController.experiences,
              onChanged: (value) {
                controller.selectedExperienceId.value = value ?? '';
                controller.applyFilters();
              },
            ),
            _filterDropdown(
              label: 'Sort By',
              value: controller.selectedSortBy.value,
              options: ArtistListingController.sortOptions,
              onChanged: (value) {
                controller.selectedSortBy.value = value ?? 'popularity';
                controller.applyFilters();
              },
            ),
            TextButton(
              onPressed: controller.clearFilters,
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<ArtistFilterOption> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6E5),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: ArtistListingPage._green, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          hint: Text(
            label,
            style: const TextStyle(color: ArtistListingPage._green, fontSize: 13),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: ArtistListingPage._green),
          isDense: true,
          style: const TextStyle(color: ArtistListingPage._green, fontSize: 13),
          selectedItemBuilder: (context) => [
            Text(
              '$label : All',
              style: const TextStyle(
                color: ArtistListingPage._green,
                fontSize: 13,
              ),
            ),
            ...options.map(
              (option) => Text(
                '$label : ${option.name}',
                style: const TextStyle(
                  color: ArtistListingPage._green,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text('All $label', style: const TextStyle(fontSize: 13)),
            ),
            ...options.map(
              (option) => DropdownMenuItem<String>(
                value: option.id,
                child: Text(option.name, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_outlined, size: 54, color: ArtistListingPage._muted),
            const SizedBox(height: 12),
            Text('No artists found', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
              'Try changing or clearing your filters.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: ArtistListingPage._muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: controller.clearFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({required this.artist});

  final ArtistProfileListingModel artist;

  static const Color _green = Color(0xFF4B8B2E);
  static const Color _purple = Color(0xFF4D3D80);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9EAEA),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCover(),
          const SizedBox(height: 8),
          _detailRow('Category', artist.category.name),
          _detailRow('Industry', artist.industry.name),
          _detailRow('Experience', artist.experience),
          _detailRow('Popular Movies', '${artist.popularMoviesCount}+'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Get.to(
                      () => ProfilePage(userId: artist.userId),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'VIEW PROFILE',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.snackbar(
                        'Contact artist',
                        artist.phoneNumber?.isNotEmpty == true
                            ? 'Contact: ${artist.phoneNumber}'
                            : 'Contact details will be available when artist APIs are connected.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _purple,
                      side: const BorderSide(color: _purple, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: const Text(
                      'CONTACT',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox(
        height: 205,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if ((artist.coverImage ?? artist.profileImage)?.isNotEmpty == true)
              Image.network(
                (artist.coverImage ?? artist.profileImage)!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _coverPlaceholder(),
              )
            else
              _coverPlaceholder(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC170B12)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      artist.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (artist.isVerified) ...[
                    const SizedBox(width: 7),
                    const Icon(Icons.verified, color: Color(0xFF2196F3), size: 24),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 9,
              right: 9,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF4B740), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      artist.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5D4256), Color(0xFFB77C65), Color(0xFF302C3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_outline_rounded,
          size: 92,
          color: Colors.white.withValues(alpha: 0.72),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFD9CACA))),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF64606A), fontSize: 15),
          children: [
            TextSpan(text: '$label : '),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF24202A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
