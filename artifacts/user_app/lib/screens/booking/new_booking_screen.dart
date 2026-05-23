import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class NewBookingScreen extends StatefulWidget {
  final Salon salon;
  final Service service;

  const NewBookingScreen({
    super.key,
    required this.salon,
    required this.service,
  });

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  int _currentStep = 0;
  DateTime _selectedDate = DateTime.now();
  StaffMember? _selectedStaff;
  TimeSlot? _selectedTimeSlot;
  List<StaffMember> _staff = [];
  List<TimeSlot> _timeSlots = [];
  bool _isLoadingStaff = true;
  bool _isLoadingAvailability = false;
  final TextEditingController _notesController = TextEditingController();
  bool _isCreatingBooking = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _loadAvailability();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    try {
      final list = await ApiService.getSalonStaff(widget.salon.id);
      setState(() {
        _staff = list.where((s) => s.isAvailable).toList();
        _isLoadingStaff = false;
      });
    } catch (e) {
      debugPrint('Error loading staff: $e');
      setState(() {
        _isLoadingStaff = false;
      });
    }
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoadingAvailability = true;
      _selectedTimeSlot = null;
    });
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final slots = await ApiService.getSalonAvailability(
        widget.salon.id,
        formattedDate,
        widget.service.id,
      );
      setState(() {
        _timeSlots = slots;
        _isLoadingAvailability = false;
      });
    } catch (e) {
      debugPrint('Error loading slots: $e');
      setState(() {
        _isLoadingAvailability = false;
      });
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadAvailability();
  }

  Future<void> _submitBooking() async {
    if (_selectedTimeSlot == null) return;

    setState(() {
      _isCreatingBooking = true;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final staffId = _selectedStaff?.id ?? _selectedTimeSlot!.staffId;

      await ApiService.createBooking(
        widget.salon.id,
        widget.service.id,
        staffId,
        formattedDate,
        _selectedTimeSlot!.time,
        _notesController.text.trim(),
      );

      // Show success dialog and navigate back
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radius),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          title: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 48),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Booking Confirmed!',
                style: GoogleFonts.inter(color: AppColors.foreground, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Your appointment has been successfully scheduled. You can track its status in the Bookings tab.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Pop back to salon details and home
                  Navigator.pop(context); // pop dialog
                  Navigator.pop(context); // pop booking wizard
                  Navigator.pop(context); // pop salon details
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.primaryForeground,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radius),
                  ),
                ),
                child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: ${e.toString().replaceAll("Exception: ", "")}', style: GoogleFonts.inter()),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      setState(() {
        _isCreatingBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book Appointment',
          style: GoogleFonts.inter(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Step indicators
          _buildStepIndicators(),
          const Divider(color: AppColors.border, height: 1),

          // Step Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStepBody(),
            ),
          ),

          // Bottom navigation buttons
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildStepIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepNode(0, 'Stylist & Date'),
          _buildStepLine(0),
          _buildStepNode(1, 'Time Slot'),
          _buildStepLine(1),
          _buildStepNode(2, 'Confirm'),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String label) {
    final isActive = _currentStep == index;
    final isDone = _currentStep > index;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? AppColors.primary
                : isActive
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.card,
            border: Border.all(
              color: isDone || isActive ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: AppColors.primaryForeground)
                : Text(
                    '${index + 1}',
                    style: GoogleFonts.inter(
                      color: isActive ? AppColors.primary : AppColors.mutedForeground,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? AppColors.foreground : AppColors.mutedForeground,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int index) {
    final isDone = _currentStep > index;
    return Container(
      width: 48,
      height: 1.5,
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
      color: isDone ? AppColors.primary : AppColors.border,
    );
  }

  Widget _buildStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    final today = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Horizontal calendar scroll
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 14,
            itemBuilder: (context, idx) {
              final date = today.add(Duration(days: idx));
              final isSelected = date.day == _selectedDate.day &&
                  date.month == _selectedDate.month &&
                  date.year == _selectedDate.year;

              return GestureDetector(
                onTap: () => _onDateSelected(date),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: GoogleFonts.inter(
                          color: isSelected ? AppColors.primaryForeground : AppColors.mutedForeground,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        date.day.toString(),
                        style: GoogleFonts.inter(
                          color: isSelected ? AppColors.primaryForeground : AppColors.foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),

        Text(
          'Select Stylist (Optional)',
          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_isLoadingStaff)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else if (_staff.isEmpty)
          Text(
            'No stylists available for this date.',
            style: GoogleFonts.inter(color: AppColors.mutedForeground),
          )
        else ...[
          // Option for "Any Stylist"
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedStaff = null;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _selectedStaff == null ? AppColors.primary.withOpacity(0.05) : AppColors.card,
                borderRadius: BorderRadius.circular(AppColors.radius),
                border: Border.all(
                  color: _selectedStaff == null ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.muted),
                    child: const Icon(Icons.people_outline, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Any Stylist (First Available)',
                    style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_selectedStaff == null)
                    const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
          // Stylist list
          ..._staff.map((stylist) {
            final isSelected = _selectedStaff?.id == stylist.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStaff = stylist;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.muted),
                      child: ClipOval(
                        child: stylist.avatarUrl != null
                            ? Image.network(
                                stylist.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person, color: AppColors.primary),
                              )
                            : const Icon(Icons.person, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stylist.name,
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        if (stylist.specialization != null)
                          Text(
                            stylist.specialization!,
                            style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time Slot',
          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Available times for ${DateFormat('EEEE, MMMM d').format(_selectedDate)}',
          style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12),
        ),
        const SizedBox(height: 20),
        if (_isLoadingAvailability)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else if (_timeSlots.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Text(
                'No available slots for this date.',
                style: GoogleFonts.inter(color: AppColors.mutedForeground),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: _timeSlots.length,
            itemBuilder: (context, idx) {
              final slot = _timeSlots[idx];
              final isSelected = _selectedTimeSlot?.time == slot.time;
              final isAvailable = slot.available;

              return GestureDetector(
                onTap: isAvailable
                    ? () {
                        setState(() {
                          _selectedTimeSlot = slot;
                        });
                      }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isAvailable
                            ? AppColors.card
                            : AppColors.muted.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : isAvailable
                              ? AppColors.border
                              : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      slot.time,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? AppColors.primaryForeground
                            : isAvailable
                                ? AppColors.foreground
                                : AppColors.mutedForeground.withOpacity(0.4),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStep3() {
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Booking Summary',
          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Summary Slip
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppColors.radius),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.salon.name,
                style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.salon.address,
                style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12),
              ),
              const Divider(color: AppColors.border, height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Service', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13)),
                  Text(widget.service.name, style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Duration', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13)),
                  Text('${widget.service.durationMinutes} min', style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Stylist', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13)),
                  Text(
                    _selectedStaff?.name ?? 'First Available Stylist',
                    style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13)),
                  Text(formattedDate, style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Time', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13)),
                  Text(_selectedTimeSlot?.time ?? '', style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(color: AppColors.border, height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Price', style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('\$${widget.service.price.toStringAsFixed(2)}', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Booking Notes input
        Text(
          'Add Notes (Optional)',
          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'e.g. skin allergies, preferred style elements...',
            hintStyle: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12),
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppColors.radius),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppColors.radius),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppColors.radius),
              borderSide: const BorderSide(color: AppColors.primary, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
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
                  'Back',
                  style: GoogleFonts.inter(color: AppColors.foreground),
                ),
              ),
            )
          else
            const SizedBox(),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Next / Confirm button
          Expanded(
            child: ElevatedButton(
              onPressed: _isNextDisabled()
                  ? null
                  : () {
                      if (_currentStep < 2) {
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        _submitBooking();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                disabledBackgroundColor: AppColors.muted,
                disabledForegroundColor: AppColors.mutedForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.radius),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isCreatingBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: AppColors.primaryForeground, strokeWidth: 2),
                    )
                  : Text(
                      _currentStep == 2 ? 'Confirm Booking' : 'Continue',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isNextDisabled() {
    if (_currentStep == 1 && _selectedTimeSlot == null) {
      return true;
    }
    return false;
  }
}
