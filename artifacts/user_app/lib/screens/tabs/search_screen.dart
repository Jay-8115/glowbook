import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../salon/salon_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialCategory;

  const SearchScreen({super.key, this.initialCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Salon> _salons = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String _selectedCategory = '';
  double _minRating = 0.0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadCategories();
    _fetchSalons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      setState(() {
        _categories = cats;
      });
    } catch (e) {
      debugPrint('Failed to load categories in search: $e');
    }
  }

  Future<void> _fetchSalons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final results = await ApiService.getSalons(
        search: _searchController.text,
        category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
      );

      // Client-side rating filter
      var filtered = results;
      if (_minRating > 0) {
        filtered = results.where((salon) => salon.avgRating >= _minRating).toList();
      }

      setState(() {
        _salons = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: GoogleFonts.inter(
                          color: AppColors.foreground,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.foreground),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  
                  // Category Filter
                  Text(
                    'Category',
                    style: GoogleFonts.inter(
                      color: AppColors.foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length + 1,
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final catName = isAll ? 'All' : _categories[index - 1].name;
                        final isSelected = isAll ? _selectedCategory.isEmpty : _selectedCategory == catName;

                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              catName,
                              style: GoogleFonts.inter(
                                color: isSelected ? AppColors.primaryForeground : AppColors.foreground,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.card,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: 1,
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedCategory = isAll ? '' : catName;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rating Filter
                  Text(
                    'Minimum Rating',
                    style: GoogleFonts.inter(
                      color: AppColors.foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [1.0, 2.0, 3.0, 4.0, 4.5].map((rating) {
                      final isSelected = _minRating == rating;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  rating.toString(),
                                  style: GoogleFonts.inter(
                                    color: isSelected ? AppColors.primaryForeground : AppColors.foreground,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.star,
                                  color: isSelected ? AppColors.primaryForeground : AppColors.primary,
                                  size: 11,
                                ),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.card,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: 1,
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                _minRating = selected ? rating : 0.0;
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedCategory = '';
                              _minRating = 0.0;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppColors.radius),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Reset All',
                            style: GoogleFonts.inter(color: AppColors.foreground),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _fetchSalons();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.primaryForeground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppColors.radius),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Apply Filters',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Salons',
          style: GoogleFonts.inter(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppColors.radius),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search salon name, city...',
                        hintStyle: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _fetchSalons(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilterModal,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppColors.radius),
                      border: Border.all(
                        color: _selectedCategory.isNotEmpty || _minRating > 0
                            ? AppColors.primary
                            : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: _selectedCategory.isNotEmpty || _minRating > 0
                          ? AppColors.primary
                          : AppColors.foreground,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.destructive, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: GoogleFonts.inter(
                            color: AppColors.foreground,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppColors.mutedForeground,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchSalons,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.primaryForeground,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _salons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, color: AppColors.mutedForeground, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'No salons found',
                            style: GoogleFonts.inter(
                              color: AppColors.foreground,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try modifying your search or filters.',
                            style: GoogleFonts.inter(
                              color: AppColors.mutedForeground,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _salons.length,
                      itemBuilder: (context, index) {
                        final salon = _salons[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SalonDetailScreen(salonId: salon.id),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(AppColors.radius),
                              border: Border.all(color: AppColors.border, width: 1),
                            ),
                            child: Row(
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(AppColors.radius)),
                                  child: SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: salon.imageUrl != null && salon.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            salon.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                _buildThumbnailPlaceholder(),
                                          )
                                        : _buildThumbnailPlaceholder(),
                                  ),
                                ),
                                // Details
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          salon.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: AppColors.foreground,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          salon.address,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: AppColors.mutedForeground,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.star, color: AppColors.primary, size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  salon.avgRating.toStringAsFixed(1),
                                                  style: GoogleFonts.inter(
                                                    color: AppColors.foreground,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '(${salon.totalReviews})',
                                                  style: GoogleFonts.inter(
                                                    color: AppColors.mutedForeground,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (salon.isVerified)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                      color: AppColors.primary.withOpacity(0.25), width: 0.5),
                                                ),
                                                child: Text(
                                                  'VERIFIED',
                                                  style: GoogleFonts.inter(
                                                    color: AppColors.primary,
                                                    fontSize: 7.5,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      color: AppColors.muted,
      child: const Center(
        child: Icon(Icons.store, color: AppColors.primary, size: 28),
      ),
    );
  }
}
