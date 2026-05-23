import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../salon/salon_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> _categories = [];
  List<Salon> _trendingSalons = [];
  List<Salon> _nearbySalons = [];
  List<Salon> _topRatedSalons = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final categoriesFuture = ApiService.getCategories();
      final featuredFuture = ApiService.getFeaturedSalons();

      final results = await Future.wait([categoriesFuture, featuredFuture]);
      
      final categories = results[0] as List<Category>;
      final featuredMap = results[1] as Map<String, List<Salon>>;

      setState(() {
        _categories = categories;
        _trendingSalons = featuredMap['trending'] ?? [];
        _nearbySalons = featuredMap['nearby'] ?? [];
        _topRatedSalons = featuredMap['topRated'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'hair':
      case 'scissors':
        return Icons.content_cut;
      case 'spa':
      case 'lotus':
        return Icons.spa;
      case 'nails':
      case 'hand':
        return Icons.back_hand;
      case 'makeup':
      case 'brush':
        return Icons.face_retouching_natural;
      case 'massage':
        return Icons.hot_tub;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'New York, NY',
                                style: GoogleFonts.inter(
                                  color: AppColors.foreground,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 16),
                            ],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user != null ? 'Hello, ${user.name}' : 'Welcome to GlowBook',
                            style: GoogleFonts.inter(
                              color: AppColors.mutedForeground,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.card,
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: ClipOval(
                          child: user?.avatarUrl != null
                              ? Image.network(
                                  user!.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, color: AppColors.primary),
                                )
                              : const Icon(Icons.person, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_errorMessage.isNotEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.destructive, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load content',
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
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.primaryForeground,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppColors.radius),
                              ),
                            ),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildListDelegate([
                    // Title Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find and Book',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: AppColors.foreground,
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              text: 'Premium ',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.foreground,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Services',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Categories List
                    if (_categories.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Categories',
                          style: GoogleFonts.inter(
                            color: AppColors.foreground,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            return GestureDetector(
                              onTap: () {
                                // For now, we print or can trigger Search navigation
                                // We will pass category back or use state provider if needed.
                                // Actually, let's allow tapping and show toast or trigger search later.
                              },
                              child: Container(
                                width: 75,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(color: AppColors.border, width: 1),
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(cat.icon),
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      cat.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: AppColors.foreground,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Trending Salons
                    if (_trendingSalons.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader('Trending Now'),
                      const SizedBox(height: 12),
                      _buildSalonHorizontalList(_trendingSalons),
                    ],

                    // Nearby Salons
                    if (_nearbySalons.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader('Nearby Salons'),
                      const SizedBox(height: 12),
                      _buildSalonHorizontalList(_nearbySalons),
                    ],

                    // Top Rated Salons
                    if (_topRatedSalons.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader('Top Rated'),
                      const SizedBox(height: 12),
                      _buildSalonHorizontalList(_topRatedSalons),
                    ],

                    const SizedBox(height: 40),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.foreground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'See All',
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalonHorizontalList(List<Salon> salons) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: salons.length,
        itemBuilder: (context, index) {
          final salon = salons[index];
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
              width: 220,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppColors.radius),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppColors.radius)),
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: salon.imageUrl != null && salon.imageUrl!.isNotEmpty
                          ? Image.network(
                              salon.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                            )
                          : _buildPlaceholderImage(),
                    ),
                  ),
                  // Details
                  Padding(
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.mutedForeground, size: 12),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${salon.city}${salon.distanceKm != null ? " • ${salon.distanceKm!.toStringAsFixed(1)} km" : ""}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppColors.mutedForeground,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
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
                                const SizedBox(width: 2),
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
                                ),
                                child: Text(
                                  'VERIFIED',
                                  style: GoogleFonts.inter(
                                    color: AppColors.primary,
                                    fontSize: 8,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.muted, AppColors.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.store, color: AppColors.primary, size: 36),
      ),
    );
  }
}
