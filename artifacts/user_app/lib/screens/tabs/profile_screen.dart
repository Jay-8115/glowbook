import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: auth.user?.name ?? '');
    _phoneController = TextEditingController(text: auth.user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateProfile(
        _nameController.text.trim(),
        _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully', style: GoogleFonts.inter(color: AppColors.primaryForeground)),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.inter(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.destructive),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameController.text = user?.name ?? '';
                  _phoneController.text = user?.phone ?? '';
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.card,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: user?.avatarUrl != null
                            ? Image.network(
                                user!.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person, color: AppColors.primary, size: 48),
                              )
                            : const Icon(Icons.person, color: AppColors.primary, size: 48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.name ?? 'User Name',
                style: GoogleFonts.inter(
                  color: AppColors.foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user?.email ?? 'user@example.com',
                style: GoogleFonts.inter(
                  color: AppColors.mutedForeground,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email Read-Only Field
                    Text(
                      'Email Address',
                      style: GoogleFonts.inter(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(AppColors.radius),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Text(
                        user?.email ?? '',
                        style: GoogleFonts.inter(
                          color: AppColors.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Full Name Field
                    Text(
                      'Full Name',
                      style: GoogleFonts.inter(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing && !_isSaving,
                      style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _isEditing ? AppColors.input : AppColors.card,
                        hintText: 'Enter your full name',
                        hintStyle: GoogleFonts.inter(color: AppColors.mutedForeground),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppColors.radius),
                          borderSide: BorderSide(
                            color: _isEditing ? AppColors.primary : AppColors.border,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppColors.radius),
                          borderSide: const BorderSide(color: AppColors.border, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppColors.radius),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppColors.radius),
                          borderSide: const BorderSide(color: AppColors.border, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Phone Number Field
                    Text(
                      'Phone Number',
                      style: GoogleFonts.inter(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      enabled: _isEditing && !_isSaving,
                      style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _isEditing ? AppColors.input : AppColors.card,
                        hintText: 'Enter your phone number',
                        hintStyle: GoogleFonts.inter(color: AppColors.mutedForeground),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppColors.radius),
                          borderSide: BorderSide(
                            color: _isEditing ? AppColors.primary : AppColors.border,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppColors.radius),
                          borderSide: const BorderSide(color: AppColors.border, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppColors.radius),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppColors.radius),
                          borderSide: const BorderSide(color: AppColors.border, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Editing actions
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.primaryForeground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppColors.radius),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: AppColors.primaryForeground, strokeWidth: 2),
                                )
                              : Text(
                                  'Save Changes',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                ),
                        ),
                      )
                    else ...[
                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
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
                                  'Are you sure you want to log out of GlowBook?',
                                  style: GoogleFonts.inter(color: AppColors.mutedForeground),
                                ),
                                actions: [
                                  TextButton(
                                    child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.foreground)),
                                    onPressed: () => Navigator.pop(context, false),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.destructive,
                                      foregroundColor: AppColors.foreground,
                                    ),
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
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.destructive),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppColors.radius),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout, color: AppColors.destructive),
                              const SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: GoogleFonts.inter(color: AppColors.destructive, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
