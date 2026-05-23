import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  final int salonId;
  final String salonName;

  const AnalyticsScreen({
    super.key,
    required this.salonId,
    required this.salonName,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  SalonStats? _stats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final stats = await ApiService.getSalonStats(widget.salonId);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Analytics Console',
          style: GoogleFonts.inter(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _fetchStats,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : _errorMessage.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.destructive, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load analytics',
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
                            onPressed: _fetchStats,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.primaryForeground,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppColors.radius),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchStats,
                    color: AppColors.primary,
                    backgroundColor: AppColors.card,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.card,
                                  const Color(0xFF2A2210),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppColors.radius),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'PERFORMANCE REPORT',
                                      style: GoogleFonts.inter(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.salonName,
                                  style: GoogleFonts.inter(
                                    color: AppColors.foreground,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Real-time automated analytics reporting console.',
                                  style: GoogleFonts.inter(
                                    color: AppColors.mutedForeground,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Revenue & Bookings Overview
                          Text(
                            'Financial Overview',
                            style: GoogleFonts.inter(
                              color: AppColors.foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildBigMetricCard(
                                  title: 'Lifetime Revenue',
                                  value: '\$${_stats!.totalRevenue.toStringAsFixed(2)}',
                                  subtitle: 'Aggregate earnings',
                                  icon: Icons.monetization_on,
                                  iconColor: const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildBigMetricCard(
                                  title: 'This Month',
                                  value: '\$${_stats!.thisMonthRevenue.toStringAsFixed(2)}',
                                  subtitle: 'Current billing period',
                                  icon: Icons.trending_up,
                                  iconColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Bookings Overview
                          Text(
                            'Volume & Bookings Ratios',
                            style: GoogleFonts.inter(
                              color: AppColors.foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildBigMetricCard(
                                  title: 'Total Appointments',
                                  value: _stats!.totalBookings.toString(),
                                  subtitle: 'Bookings serviced',
                                  icon: Icons.bookmark_add,
                                  iconColor: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildBigMetricCard(
                                  title: 'This Month Load',
                                  value: _stats!.thisMonthBookings.toString(),
                                  subtitle: 'Monthly appointments',
                                  icon: Icons.calendar_month,
                                  iconColor: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Appointments Distribution By Status
                          Text(
                            'Status Breakdown',
                            style: GoogleFonts.inter(
                              color: AppColors.foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(AppColors.radius),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_stats!.totalBookings == 0)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: Text(
                                        'No booking data to analyze.',
                                        style: GoogleFonts.inter(
                                          color: AppColors.mutedForeground,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                else ...[
                                  _buildProgressBar(
                                    statusLabel: 'Completed Appointments',
                                    count: _stats!.bookingsByStatus['completed'] ?? 0,
                                    total: _stats!.totalBookings,
                                    color: const Color(0xFF10B981),
                                  ),
                                  const Divider(height: 24, color: AppColors.border),
                                  _buildProgressBar(
                                    statusLabel: 'Active/In-Progress',
                                    count: _stats!.bookingsByStatus['in_progress'] ?? 0,
                                    total: _stats!.totalBookings,
                                    color: Colors.amberAccent,
                                  ),
                                  const Divider(height: 24, color: AppColors.border),
                                  _buildProgressBar(
                                    statusLabel: 'Accepted Appointments',
                                    count: _stats!.bookingsByStatus['accepted'] ?? 0,
                                    total: _stats!.totalBookings,
                                    color: AppColors.primary,
                                  ),
                                  const Divider(height: 24, color: AppColors.border),
                                  _buildProgressBar(
                                    statusLabel: 'Pending Review',
                                    count: _stats!.bookingsByStatus['pending'] ?? 0,
                                    total: _stats!.totalBookings,
                                    color: Colors.blueAccent,
                                  ),
                                  const Divider(height: 24, color: AppColors.border),
                                  _buildProgressBar(
                                    statusLabel: 'Cancelled Appointments',
                                    count: _stats!.bookingsByStatus['cancelled'] ?? 0,
                                    total: _stats!.totalBookings,
                                    color: AppColors.destructive,
                                  ),
                                ]
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Customer Ratings & Reviews
                          Text(
                            'Quality Metrics',
                            style: GoogleFonts.inter(
                              color: AppColors.foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(AppColors.radius),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      _stats!.avgRating.toStringAsFixed(1),
                                      style: GoogleFonts.inter(
                                        color: AppColors.foreground,
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: List.generate(5, (index) {
                                        final isGold = index < _stats!.avgRating.round();
                                        return Icon(
                                          isGold ? Icons.star : Icons.star_border,
                                          color: AppColors.primary,
                                          size: 14,
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_stats!.totalReviews} reviews',
                                      style: GoogleFonts.inter(
                                        color: AppColors.mutedForeground,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildStatusItem(
                                        icon: Icons.people_outline,
                                        label: 'Active Salon Customers',
                                        value: '${_stats!.activeCustomers} customers',
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStatusItem(
                                        icon: Icons.workspace_premium_outlined,
                                        label: 'Satisfaction Rating',
                                        value: _stats!.avgRating >= 4.5
                                            ? 'Excellent Quality'
                                            : _stats!.avgRating >= 4.0
                                                ? 'Great Quality'
                                                : 'Fair Quality',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildBigMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: iconColor, size: 16),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.foreground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: AppColors.mutedForeground,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String statusLabel,
    required int count,
    required int total,
    required Color color,
  }) {
    final double pct = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              statusLabel,
              style: GoogleFonts.inter(
                color: AppColors.foreground,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count bookings (${(pct * 100).toStringAsFixed(0)}%)',
              style: GoogleFonts.inter(
                color: AppColors.mutedForeground,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.muted,
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.mutedForeground,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: AppColors.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
