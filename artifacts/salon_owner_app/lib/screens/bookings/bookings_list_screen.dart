import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class BookingsListScreen extends StatefulWidget {
  final int salonId;

  const BookingsListScreen({super.key, required this.salonId});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final Map<int, bool> _mutatingBookings = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Pass role: 'owner' to get salon bookings
      final list = await ApiService.getBookings(role: 'owner');
      
      // Filter by this specific salonId just in case they have multiple
      final filtered = list.where((b) => b.salonId == widget.salonId).toList();

      setState(() {
        _bookings = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int bookingId, String newStatus) async {
    setState(() {
      _mutatingBookings[bookingId] = true;
    });

    try {
      await ApiService.updateBookingStatus(bookingId, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking status updated to $newStatus', style: GoogleFonts.inter(color: AppColors.primaryForeground)),
          backgroundColor: AppColors.primary,
        ),
      );
      // Reload bookings
      final list = await ApiService.getBookings(role: 'owner');
      final filtered = list.where((b) => b.salonId == widget.salonId).toList();
      setState(() {
        _bookings = filtered;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      setState(() {
        _mutatingBookings[bookingId] = false;
      });
    }
  }

  List<Booking> get _activeBookings {
    final active = ['pending', 'confirmed', 'in_progress'];
    return _bookings.where((b) => active.contains(b.status.toLowerCase())).toList()
      ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
  }

  List<Booking> get _finishedBookings {
    final finished = ['completed', 'cancelled', 'declined'];
    return _bookings.where((b) => finished.contains(b.status.toLowerCase())).toList()
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
          'Manage Appointments',
          style: GoogleFonts.inter(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedForeground,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Active Roster'),
            Tab(text: 'Finished'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
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
                              Text('Something went wrong', style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(_errorMessage, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13)),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadBookings,
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.primaryForeground),
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
                      _buildBookingsTab(_activeBookings, 'No active appointments', true),
                      _buildBookingsTab(_finishedBookings, 'No historical appointments', false),
                    ],
                  ),
      ),
    );
  }

  Widget _buildBookingsTab(List<Booking> list, String emptyMsg, bool isActiveRoster) {
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
                    emptyMsg,
                    style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appointments booked by customers will show up here.',
                    style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13),
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
        final isMutating = _mutatingBookings[booking.id] ?? false;
        final parsedDate = DateTime.tryParse(booking.bookingDate) ?? DateTime.now();
        final formattedDate = DateFormat('EEE, MMM d, yyyy').format(parsedDate);

        return Container(
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
              // Client Header Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.user?.name ?? 'Client Name',
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        if (booking.user?.phone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            booking.user!.phone!,
                            style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11),
                          ),
                        ],
                      ],
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
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),

              // Booking details
              Row(
                children: [
                  const Icon(Icons.cut_outlined, color: AppColors.mutedForeground, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    booking.service?.name ?? 'Service',
                    style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '\$${booking.totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: AppColors.mutedForeground, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    '$formattedDate at ${booking.startTime}',
                    style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12.5),
                  ),
                ],
              ),
              if (booking.staff != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, color: AppColors.mutedForeground, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'Stylist: ${booking.staff!.name}',
                      style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12.5),
                    ),
                  ],
                ),
              ],
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.muted.withOpacity(0.4), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    'Notes: ${booking.notes!}',
                    style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11.5, height: 1.3),
                  ),
                ),
              ],

              // Owner status mutators
              if (isActiveRoster) ...[
                const Divider(color: AppColors.border, height: 28),
                _buildActionButtons(booking, isMutating),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(Booking booking, bool isMutating) {
    if (isMutating) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)));
    }

    final status = booking.status.toLowerCase();

    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus(booking.id, 'declined'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.destructive),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Decline', style: GoogleFonts.inter(color: AppColors.destructive, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(booking.id, 'confirmed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Accept', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    if (status == 'confirmed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus(booking.id, 'in_progress'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Start Appointment', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      );
    }

    if (status == 'in_progress') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus(booking.id, 'cancelled'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.destructive),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Cancel Appointment', style: GoogleFonts.inter(color: AppColors.destructive, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(booking.id, 'completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Complete Service', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    return const SizedBox();
  }
}
