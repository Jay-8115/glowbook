import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Booking? _booking;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final res = await ApiService.getBooking(widget.bookingId);
      setState(() {
        _booking = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
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

  Future<void> _cancelBooking() async {
    if (_booking == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: Text(
          'Cancel Appointment',
          style: GoogleFonts.inter(color: AppColors.foreground, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            child: Text('Keep Booking', style: GoogleFonts.inter(color: AppColors.foreground)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: AppColors.foreground,
            ),
            child: Text('Yes, Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      await ApiService.updateBookingStatus(_booking!.id, 'cancelled');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking cancelled successfully', style: GoogleFonts.inter(color: AppColors.primaryForeground)),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context, true); // Pop back with refresh signal
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel booking: $e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      setState(() {
        _isCancelling = false;
      });
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

    if (_errorMessage.isNotEmpty || _booking == null) {
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
                  onPressed: _loadBookingDetails,
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

    final booking = _booking!;
    final parsedDate = DateTime.tryParse(booking.bookingDate) ?? DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(parsedDate);
    final canCancel = ['pending', 'confirmed'].contains(booking.status.toLowerCase());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Booking Details',
          style: GoogleFonts.inter(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppColors.radius),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment Status',
                        style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.status.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: _getStatusColor(booking.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Salon Details Section
            Text(
              'Salon Info',
              style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppColors.radius),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.salon?.name ?? 'Salon Name',
                    style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.mutedForeground, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.salon?.address ?? 'Salon Address',
                          style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  if (booking.salon?.phone != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: AppColors.primary, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          booking.salon!.phone!,
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Service details
            Text(
              'Service Details',
              style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppColors.radius),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.service?.name ?? 'Service Name',
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        if (booking.service?.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            booking.service!.description!,
                            style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: AppColors.mutedForeground, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.service?.durationMinutes ?? 0} min',
                              style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '\$${booking.totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date, Time & Stylist
            Text(
              'Appointment Schedule',
              style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppColors.radius),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 16),
                      const SizedBox(width: 10),
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.primary, size: 16),
                      const SizedBox(width: 10),
                      Text(
                        booking.startTime,
                        style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (booking.staff != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, color: AppColors.primary, size: 16),
                        const SizedBox(width: 10),
                        Text(
                          'Stylist: ${booking.staff!.name}',
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              Text(
                'Booking Notes',
                style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppColors.radius),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Text(
                  booking.notes!,
                  style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Action Buttons
            if (canCancel)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCancelling ? null : _cancelBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: AppColors.foreground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radius),
                    ),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Cancel Appointment',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
