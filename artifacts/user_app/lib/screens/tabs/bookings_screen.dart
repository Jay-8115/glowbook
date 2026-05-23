import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../booking/booking_detail_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final results = await ApiService.getBookings();
      setState(() {
        _bookings = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<Booking> get _upcomingBookings {
    final activeStatuses = ['pending', 'confirmed', 'in_progress'];
    return _bookings.where((b) => activeStatuses.contains(b.status.toLowerCase())).toList()
      ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
  }

  List<Booking> get _pastBookings {
    final pastStatuses = ['completed', 'cancelled', 'declined'];
    return _bookings.where((b) => pastStatuses.contains(b.status.toLowerCase())).toList()
      ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return AppColors.primary;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
      case 'declined':
        return AppColors.destructive;
      default:
        return AppColors.mutedForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: GoogleFonts.inter(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedForeground,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBookings,
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
                                'Failed to fetch bookings',
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
                                onPressed: _fetchBookings,
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
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingsList(_upcomingBookings, 'No upcoming bookings'),
                      _buildBookingsList(_pastBookings, 'No past bookings'),
                    ],
                  ),
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> list, String emptyMessage) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_outlined, color: AppColors.mutedForeground, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: GoogleFonts.inter(
                      color: AppColors.foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book a slot with your favorite salons!',
                    style: GoogleFonts.inter(
                      color: AppColors.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final booking = list[index];
        final parsedDate = DateTime.tryParse(booking.bookingDate) ?? DateTime.now();
        final formattedDate = DateFormat('EEE, MMM d, yyyy').format(parsedDate);

        return GestureDetector(
          onTap: () async {
            final didCancel = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailScreen(bookingId: booking.id),
              ),
            );
            if (didCancel == true) {
              _fetchBookings();
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppColors.radius),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Salon name & Status)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.salon?.name ?? 'Salon Name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: _getStatusColor(booking.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 24),

                // Booking Details
                Row(
                  children: [
                    const Icon(Icons.cut_outlined, color: AppColors.mutedForeground, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.service?.name ?? 'Service Name',
                        style: GoogleFonts.inter(
                          color: AppColors.foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: AppColors.mutedForeground, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '$formattedDate at ${booking.startTime}',
                      style: GoogleFonts.inter(
                        color: AppColors.mutedForeground,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (booking.staff != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: AppColors.mutedForeground, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Stylist: ${booking.staff!.name}',
                        style: GoogleFonts.inter(
                          color: AppColors.mutedForeground,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(color: AppColors.border, height: 24),

                // Total Price and Action link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Price',
                          style: GoogleFonts.inter(
                            color: AppColors.mutedForeground,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '\$${booking.totalPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'View Details',
                          style: GoogleFonts.inter(
                            color: AppColors.foreground,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppColors.foreground, size: 18),
                      ],
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
}
