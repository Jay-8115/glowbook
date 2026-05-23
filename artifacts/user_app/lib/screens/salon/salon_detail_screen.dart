import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../booking/new_booking_screen.dart';

class SalonDetailScreen extends StatefulWidget {
  final int salonId;

  const SalonDetailScreen({super.key, required this.salonId});

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Salon? _salon;
  List<Service> _services = [];
  List<StaffMember> _staff = [];
  List<Review> _reviews = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  String _errorMessage = '';
  Service? _selectedService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSalonDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSalonDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final salonFuture = ApiService.getSalon(widget.salonId);
      final servicesFuture = ApiService.getSalonServices(widget.salonId);
      final staffFuture = ApiService.getSalonStaff(widget.salonId);
      final reviewsFuture = ApiService.getSalonReviews(widget.salonId);

      final results = await Future.wait([
        salonFuture,
        servicesFuture,
        staffFuture,
        reviewsFuture,
      ]);

      setState(() {
        _salon = results[0] as Salon;
        _isFavorite = _salon?.isFavorited ?? false;
        _services = (results[1] as List<Service>).where((s) => s.isActive).toList();
        _staff = (results[2] as List<StaffMember>).where((s) => s.isAvailable).toList();
        _reviews = results[3] as List<Review>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_salon == null) return;
    final originalState = _isFavorite;
    setState(() {
      _isFavorite = !originalState;
    });

    try {
      if (originalState) {
        await ApiService.removeFavorite(_salon!.id);
      } else {
        await ApiService.addFavorite(_salon!.id);
      }
    } catch (e) {
      // rollback
      setState(() {
        _isFavorite = originalState;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite status: $e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage.isNotEmpty || _salon == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.destructive, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load details',
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
                  onPressed: _loadSalonDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final salon = _salon!;

    return Scaffold(
      body: Stack(
        children: [
          // Content
          CustomScrollView(
            slivers: [
              // Hero Image & Header
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                        size: 20,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: salon.imageUrl != null && salon.imageUrl!.isNotEmpty
                      ? Image.network(
                          salon.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildHeroPlaceholder(),
                        )
                      : _buildHeroPlaceholder(),
                ),
              ),

              // Salon Info Box
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              salon.name,
                              style: GoogleFonts.inter(
                                color: AppColors.foreground,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (salon.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
                              ),
                              child: Text(
                                'VERIFIED',
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.mutedForeground, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              salon.address,
                              style: GoogleFonts.inter(
                                color: AppColors.mutedForeground,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.primary, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            salon.avgRating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              color: AppColors.foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${salon.totalReviews} reviews)',
                            style: GoogleFonts.inter(
                              color: AppColors.mutedForeground,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.access_time, color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${salon.openTime ?? "09:00"} - ${salon.closeTime ?? "21:00"}',
                            style: GoogleFonts.inter(
                              color: AppColors.foreground,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (salon.description != null && salon.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'About Us',
                          style: GoogleFonts.inter(
                            color: AppColors.foreground,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          salon.description!,
                          style: GoogleFonts.inter(
                            color: AppColors.mutedForeground,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Segmented TabBar Header
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.background,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.mutedForeground,
                    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Services'),
                      Tab(text: 'Stylists'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                ),
              ),

              // TabBar View (Needs to adapt size inside CustomScrollView or use SliverFillRemaining/custom layout)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 400, // Fixed height or list size
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildServicesList(),
                      _buildStaffList(),
                      _buildReviewsList(),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Bottom floating bar for service selection and booking
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedService != null ? 'Selected Service' : 'Total Price',
                          style: GoogleFonts.inter(
                            color: AppColors.mutedForeground,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedService != null
                              ? _selectedService!.name
                              : 'Select service...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.foreground,
                            fontSize: _selectedService != null ? 14 : 13,
                            fontWeight: _selectedService != null ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (_selectedService != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '\$${_selectedService!.price.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _selectedService == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewBookingScreen(
                                  salon: salon,
                                  service: _selectedService!,
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForeground,
                      disabledBackgroundColor: AppColors.muted,
                      disabledForegroundColor: AppColors.mutedForeground,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.radius),
                      ),
                    ),
                    child: Text(
                      'Book Appointment',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.muted, AppColors.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.store, color: AppColors.primary, size: 64),
      ),
    );
  }

  Widget _buildServicesList() {
    if (_services.isEmpty) {
      return Center(
        child: Text(
          'No services listed.',
          style: GoogleFonts.inter(color: AppColors.mutedForeground),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        final isSelected = _selectedService?.id == service.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedService = isSelected ? null : service;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.card,
              borderRadius: BorderRadius.circular(AppColors.radius),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: GoogleFonts.inter(
                          color: AppColors.foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (service.description != null && service.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          service.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.mutedForeground,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.mutedForeground, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${service.durationMinutes} min',
                            style: GoogleFonts.inter(
                              color: AppColors.mutedForeground,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${service.price.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.mutedForeground,
                          width: 1.5,
                        ),
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: AppColors.primaryForeground, size: 12)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffList() {
    if (_staff.isEmpty) {
      return Center(
        child: Text(
          'No stylists available.',
          style: GoogleFonts.inter(color: AppColors.mutedForeground),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _staff.length,
      itemBuilder: (context, index) {
        final member = _staff[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppColors.radius),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.muted,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: ClipOval(
                  child: member.avatarUrl != null
                      ? Image.network(
                          member.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, color: AppColors.primary),
                        )
                      : const Icon(Icons.person, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                member.name,
                style: GoogleFonts.inter(
                  color: AppColors.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                member.role ?? 'Stylist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsList() {
    if (_reviews.isEmpty) {
      return Center(
        child: Text(
          'No reviews yet. Be the first to review!',
          style: GoogleFonts.inter(color: AppColors.mutedForeground),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppColors.radius),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    review.user?.name ?? 'Anonymous Client',
                    style: GoogleFonts.inter(
                      color: AppColors.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (starIdx) {
                      return Icon(
                        Icons.star,
                        color: starIdx < review.rating ? AppColors.primary : AppColors.muted,
                        size: 13,
                      );
                    }),
                  ),
                ],
              ),
              if (review.comment != null && review.comment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  review.comment!,
                  style: GoogleFonts.inter(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
