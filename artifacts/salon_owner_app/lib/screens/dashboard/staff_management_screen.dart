import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class StaffManagementScreen extends StatefulWidget {
  final int salonId;

  const StaffManagementScreen({super.key, required this.salonId});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<StaffMember> _staff = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final list = await ApiService.getSalonStaff(widget.salonId);
      setState(() {
        _staff = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showStaffFormDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final roleController = TextEditingController(text: 'Stylist');
    final specController = TextEditingController();
    final avatarController = TextEditingController();
    bool isSavingLocal = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radius),
                side: const BorderSide(color: AppColors.border, width: 1),
              ),
              title: Text(
                'Add Staff Member',
                style: GoogleFonts.inter(color: AppColors.foreground, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text('Stylist Name', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nameController,
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13),
                          decoration: _inputDecoration('e.g. Sarah Jenkins'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 14),

                        // Role
                        Text('Role Title', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: roleController,
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13),
                          decoration: _inputDecoration('e.g. Senior Stylist, Color expert'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Role is required' : null,
                        ),
                        const SizedBox(height: 14),

                        // Specialization
                        Text('Specialization', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: specController,
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13),
                          decoration: _inputDecoration('e.g. Balayage, Keratin treatments'),
                        ),
                        const SizedBox(height: 14),

                        // Avatar Url
                        Text('Avatar Image Link', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: avatarController,
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13),
                          decoration: _inputDecoration('e.g. https://images.unsplash.com/...'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.foreground)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                  ),
                  onPressed: isSavingLocal
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            isSavingLocal = true;
                          });

                          try {
                            await ApiService.createStaff(
                              widget.salonId,
                              nameController.text.trim(),
                              roleController.text.trim(),
                              specController.text.trim().isEmpty ? null : specController.text.trim(),
                              avatarController.text.trim().isEmpty ? null : avatarController.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadStaff();
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
                                backgroundColor: AppColors.destructive,
                              ),
                            );
                            setDialogState(() {
                              isSavingLocal = false;
                            });
                          }
                        },
                  child: isSavingLocal
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryForeground))
                      : Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.input,
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stylists Roster',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: _showStaffFormDialog,
          ),
        ],
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
                        Text('Something went wrong', style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_errorMessage, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadStaff,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.primaryForeground),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _staff.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline, color: AppColors.mutedForeground, size: 48),
                          const SizedBox(height: 16),
                          Text('No staff members registered', style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Tap the + icon in top right to register a stylist.', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _staff.length,
                      itemBuilder: (context, index) {
                        final member = _staff[index];

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppColors.radius),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Avatar circle
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.muted,
                                  border: Border.all(
                                    color: member.isAvailable ? AppColors.primary : AppColors.mutedForeground,
                                    width: 1.5,
                                  ),
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
                              const SizedBox(height: 12),
                              Text(
                                member.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                member.role ?? 'Stylist',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                member.specialization ?? 'General cuts',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11),
                              ),
                              const SizedBox(height: 12),
                              // Availability Chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (member.isAvailable ? AppColors.success : AppColors.muted).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  member.isAvailable ? 'AVAILABLE' : 'OFF DUTY',
                                  style: GoogleFonts.inter(
                                    color: member.isAvailable ? AppColors.success : AppColors.mutedForeground,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
