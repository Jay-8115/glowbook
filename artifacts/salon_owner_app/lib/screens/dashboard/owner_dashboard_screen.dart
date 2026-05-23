import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'salon_form_screen.dart';
import 'services_management_screen.dart';
import 'staff_management_screen.dart';
import '../bookings/bookings_list_screen.dart';
import 'analytics_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<Salon> _mySalons = [];
  Salon? _selectedSalon;
  SalonStats? _stats;
  List<StaffMember> _staff = [];
  List<Booking> _bookings = [];
  final Map<int, bool> _mutatingBookings = {};
  bool _isLoading = true;
  bool _isLoadingStats = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSalons();
  }

  Future<void> _loadSalons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _stats = null;
      _staff = [];
      _bookings = [];
    });
    try {
      final list = await ApiService.getMySalons();
      setState(() {
        _mySalons = list;
        if (list.isNotEmpty) {
          _selectedSalon = list.first;
        }
        _isLoading = false;
      });

      if (_selectedSalon != null) {
        _loadSalonDetails(_selectedSalon!.id);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSalonDetails(int salonId) async {
    setState(() {
      _isLoadingStats = true;
    });
    try {
      final results = await Future.wait([
        ApiService.getSalonStats(salonId),
        ApiService.getSalonStaff(salonId),
        ApiService.getBookings(role: 'owner'),
      ]);
      setState(() {
        _stats = results[0] as SalonStats;
        _staff = results[1] as List<StaffMember>;
        final allBookings = results[2] as List<Booking>;
        _bookings = allBookings.where((b) => b.salonId == salonId).toList();
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Failed to load salon details: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _updateBookingStatus(int bookingId, String newStatus) async {
    setState(() {
      _mutatingBookings[bookingId] = true;
    });
    try {
      await ApiService.updateBookingStatus(bookingId, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking updated to "$newStatus" successfully!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
      if (_selectedSalon != null) {
        _loadSalonDetails(_selectedSalon!.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      setState(() {
        _mutatingBookings[bookingId] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GlowBook Partner',
          style: GoogleFonts.inter(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.destructive),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    side: const BorderSide(color: AppColors.border, width: 1),
                  ),
                  title: Text(
                    'Confirm Logout',
                    style: GoogleFonts.inter(color: AppColors.foreground, fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'Are you sure you want to log out of GlowBook Partner?',
                    style: GoogleFonts.inter(color: AppColors.mutedForeground),
                  ),
                  actions: [
                    TextButton(
                      child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.foreground)),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive),
                      child: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                auth.logout();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSalons,
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _errorMessage.isNotEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.destructive, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load business data',
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
                                onPressed: _loadSalons,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.primaryForeground,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : _mySalons.isEmpty
                    ? _buildEmptyState()
                    : _buildDashboardContent(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 72),
        const SizedBox(height: 24),
        Text(
          'Register Your Salon',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.foreground,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You haven\'t listed a salon yet. Create your salon profile to start accepting booking appointments.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.mutedForeground,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 36),
        ElevatedButton(
          onPressed: () async {
            final added = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SalonFormScreen()),
            );
            if (added == true) {
              _loadSalons();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.primaryForeground,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radius),
            ),
          ),
          child: Text(
            'Create Salon Profile',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSalonsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Salons (${_mySalons.length})',
              style: GoogleFonts.inter(
                color: AppColors.foreground,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Swipe to view all',
              style: GoogleFonts.inter(
                color: AppColors.mutedForeground,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _mySalons.length,
            itemBuilder: (context, index) {
              final s = _mySalons[index];
              final isSelected = _selectedSalon?.id == s.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSalon = s;
                  });
                  _loadSalonDetails(s.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 260,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 52,
                          height: 52,
                          color: AppColors.muted,
                          child: s.imageUrl != null && s.imageUrl!.isNotEmpty
                              ? Image.network(
                                  s.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.store, color: AppColors.primary),
                                )
                              : const Icon(Icons.store, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.foreground,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${s.city}${s.state != null ? ', ${s.state}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.mutedForeground,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppColors.primary, size: 10),
                                const SizedBox(width: 2),
                                Text(
                                  s.avgRating.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    color: AppColors.foreground,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.airline_seat_recline_normal, color: AppColors.mutedForeground, size: 11),
                                const SizedBox(width: 2),
                                Text(
                                  '${s.totalSeats ?? 6} Seats',
                                  style: GoogleFonts.inter(
                                    color: AppColors.mutedForeground,
                                    fontSize: 10,
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
        ),
      ],
    );
  }

  Widget _buildStylistsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stylists on Duty',
              style: GoogleFonts.inter(
                color: AppColors.foreground,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StaffManagementScreen(salonId: _selectedSalon!.id),
                  ),
                ).then((_) {
                  if (_selectedSalon != null) {
                    _loadSalonDetails(_selectedSalon!.id);
                  }
                });
              },
              child: Text(
                'Manage',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _staff.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppColors.radius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.people_outline, color: AppColors.mutedForeground, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'No stylists registered yet',
                      style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12),
                    ),
                  ],
                ),
              )
            : SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _staff.length,
                  itemBuilder: (context, index) {
                    final staff = _staff[index];
                    return Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: staff.avatarUrl != null && staff.avatarUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          staff.avatarUrl!,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Text(
                                            staff.name.substring(0, 1).toUpperCase(),
                                            style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        staff.name.substring(0, 1).toUpperCase(),
                                        style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: staff.isAvailable ? const Color(0xFF10B981) : Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.card, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            staff.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.foreground,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            staff.specialization ?? staff.role ?? 'Stylist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.mutedForeground,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildBookingsSection() {
    final activeBookings = _bookings.where((b) => b.status == 'pending' || b.status == 'accepted' || b.status == 'in_progress').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Appointments',
              style: GoogleFonts.inter(
                color: AppColors.foreground,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingsListScreen(salonId: _selectedSalon!.id),
                  ),
                ).then((_) {
                  if (_selectedSalon != null) {
                    _loadSalonDetails(_selectedSalon!.id);
                  }
                });
              },
              child: Text(
                'View All (${_bookings.length})',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        activeBookings.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppColors.radius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.mutedForeground, size: 28),
                    const SizedBox(height: 10),
                    Text(
                      'No active bookings for today',
                      style: GoogleFonts.inter(
                        color: AppColors.foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completed or cancelled appointments will show in bookings history.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.mutedForeground,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeBookings.length,
                itemBuilder: (context, index) {
                  final booking = activeBookings[index];
                  final isMutating = _mutatingBookings[booking.id] == true;
                  final int seatNo = (booking.id % (_selectedSalon!.totalSeats ?? 6)) + 1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppColors.radius),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(AppColors.radius),
                                bottomLeft: Radius.circular(AppColors.radius),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      booking.service?.name ?? 'Salon Service',
                                      style: GoogleFonts.inter(
                                        color: AppColors.foreground,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.primary, width: 0.5),
                                    ),
                                    child: Text(
                                      'Seat #$seatNo',
                                      style: GoogleFonts.inter(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: AppColors.mutedForeground, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${booking.bookingDate} at ${booking.startTime}',
                                    style: GoogleFonts.inter(
                                      color: AppColors.mutedForeground,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.monetization_on_outlined, color: AppColors.primary, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '\$${booking.totalPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      color: AppColors.foreground,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, color: AppColors.border),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CUSTOMER',
                                          style: GoogleFonts.inter(
                                            color: AppColors.mutedForeground,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          booking.user?.name ?? 'Guest User',
                                          style: GoogleFonts.inter(
                                            color: AppColors.foreground,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (booking.user?.phone != null) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone, color: AppColors.primary, size: 10),
                                              const SizedBox(width: 4),
                                              Text(
                                                booking.user!.phone!,
                                                style: GoogleFonts.inter(
                                                  color: AppColors.mutedForeground,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (booking.user?.email != null) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.email_outlined, color: AppColors.mutedForeground, size: 10),
                                              const SizedBox(width: 4),
                                              Text(
                                                booking.user!.email,
                                                style: GoogleFonts.inter(
                                                  color: AppColors.mutedForeground,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'STYLIST',
                                          style: GoogleFonts.inter(
                                            color: AppColors.mutedForeground,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline, color: AppColors.mutedForeground, size: 13),
                                            const SizedBox(width: 4),
                                            Text(
                                              booking.staff?.name ?? 'Any Stylist',
                                              style: GoogleFonts.inter(
                                                color: AppColors.foreground,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        _buildStatusBadge(booking.status),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildActionButtons(booking),
                            ],
                          ),
                        ),
                        if (isMutating)
                          Positioned.fill(
                            child: Container(
                              color: AppColors.background.withOpacity(0.55),
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = Colors.amber;
        label = 'Pending';
        break;
      case 'accepted':
        color = Colors.blue;
        label = 'Confirmed';
        break;
      case 'in_progress':
        color = AppColors.primary;
        label = 'In Progress';
        break;
      case 'completed':
        color = const Color(0xFF10B981);
        label = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = AppColors.mutedForeground;
        label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Booking booking) {
    if (booking.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.destructive),
                foregroundColor: AppColors.destructive,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: () => _updateBookingStatus(booking.id, 'cancelled'),
              child: Text(
                'Decline',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: () => _updateBookingStatus(booking.id, 'accepted'),
              child: Text(
                'Accept',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    } else if (booking.status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.primaryForeground,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onPressed: () => _updateBookingStatus(booking.id, 'in_progress'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow, size: 16),
              const SizedBox(width: 4),
              Text(
                'Start Service',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    } else if (booking.status == 'in_progress') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onPressed: () => _updateBookingStatus(booking.id, 'completed'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check, size: 16),
              const SizedBox(width: 4),
              Text(
                'Complete Service',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDashboardContent() {
    final salon = _selectedSalon!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_mySalons.length > 1) ...[
            _buildSalonsSelector(),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppColors.radius),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: AppColors.muted,
                      child: salon.imageUrl != null && salon.imageUrl!.isNotEmpty
                          ? Image.network(
                              salon.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.store, color: AppColors.primary),
                            )
                          : const Icon(Icons.store, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salon.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          salon.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            'Performance Metrics',
            style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _isLoadingStats
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)))
              : Column(
                  children: [
                    _buildMetricsGrid(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 18),
                        label: Text(
                          'Analyze Detailed Dashboard',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppColors.radius),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnalyticsScreen(
                                salonId: salon.id,
                                salonName: salon.name,
                              ),
                            ),
                          ).then((_) {
                            if (_selectedSalon != null) {
                              _loadSalonDetails(_selectedSalon!.id);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 28),

          _isLoadingStats
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    _buildStylistsSection(),
                    const SizedBox(height: 28),
                  ],
                ),

          _isLoadingStats
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    _buildBookingsSection(),
                    const SizedBox(height: 28),
                  ],
                ),

          Text(
            'Quick Actions',
            style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildActionCard(
                icon: Icons.calendar_today,
                title: 'Bookings',
                subtitle: 'Manage rosters',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingsListScreen(salonId: salon.id),
                    ),
                  ).then((_) {
                    if (_selectedSalon != null) {
                      _loadSalonDetails(_selectedSalon!.id);
                    }
                  });
                },
              ),
              _buildActionCard(
                icon: Icons.cut,
                title: 'Services',
                subtitle: 'Prices & active list',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServicesManagementScreen(salonId: salon.id),
                    ),
                  ).then((_) {
                    if (_selectedSalon != null) {
                      _loadSalonDetails(_selectedSalon!.id);
                    }
                  });
                },
              ),
              _buildActionCard(
                icon: Icons.people_outline,
                title: 'Stylists',
                subtitle: 'Stylist schedules',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StaffManagementScreen(salonId: salon.id),
                    ),
                  ).then((_) {
                    if (_selectedSalon != null) {
                      _loadSalonDetails(_selectedSalon!.id);
                    }
                  });
                },
              ),
              _buildActionCard(
                icon: Icons.edit_note,
                title: 'Salon Form',
                subtitle: 'Address & hours',
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalonFormScreen(salon: salon),
                    ),
                  );
                  if (updated == true) {
                    _loadSalons();
                  }
                },
              ),
              _buildActionCard(
                icon: Icons.analytics_outlined,
                title: 'Analyze',
                subtitle: 'Revenue & stats',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnalyticsScreen(
                        salonId: salon.id,
                        salonName: salon.name,
                      ),
                    ),
                  ).then((_) {
                    if (_selectedSalon != null) {
                      _loadSalonDetails(_selectedSalon!.id);
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final stats = _stats;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildMetricItem(
          label: 'Total Bookings',
          value: stats != null ? stats.totalBookings.toString() : '-',
          icon: Icons.bookmark_added_outlined,
        ),
        _buildMetricItem(
          label: 'Total Revenue',
          value: stats != null ? '\$${stats.totalRevenue.toStringAsFixed(0)}' : '-',
          icon: Icons.monetization_on_outlined,
        ),
        _buildMetricItem(
          label: 'This Month',
          value: stats != null ? stats.thisMonthBookings.toString() : '-',
          icon: Icons.calendar_month_outlined,
        ),
        _buildMetricItem(
          label: 'Average Rating',
          value: stats != null ? '${stats.avgRating.toStringAsFixed(1)} ★' : '-',
          icon: Icons.star_border,
        ),
      ],
    );
  }

  Widget _buildMetricItem({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Icon(icon, color: AppColors.primary, size: 16),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.foreground,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppColors.radius),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
