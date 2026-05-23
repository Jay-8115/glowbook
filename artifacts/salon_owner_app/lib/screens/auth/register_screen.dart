import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isRegistering = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isRegistering = true;
      _errorMessage = '';
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      // Register with 'owner' role
      await auth.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'owner',
      );

      // Auto pop after successful state provider update (AuthGate will auto route to dashboard)
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Partner with GlowBook',
                    style: GoogleFonts.inter(
                      color: AppColors.foreground,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create your business account to list your salon.',
                    style: GoogleFonts.inter(
                      color: AppColors.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.destructive.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppColors.radius),
                        border: Border.all(color: AppColors.destructive, width: 1),
                      ),
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.inter(color: AppColors.destructive, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Full Name
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
                    style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      hintText: 'John Doe',
                      hintStyle: GoogleFonts.inter(color: AppColors.mutedForeground),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Full Name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email
                  Text(
                    'Email Address',
                    style: GoogleFonts.inter(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      hintText: 'owner@example.com',
                      hintStyle: GoogleFonts.inter(color: AppColors.mutedForeground),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Phone Number
                  Text(
                    'Phone Number (Optional)',
                    style: GoogleFonts.inter(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      hintText: '+1 (555) 123-4567',
                      hintStyle: GoogleFonts.inter(color: AppColors.mutedForeground),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password
                  Text(
                    'Password',
                    style: GoogleFonts.inter(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      hintText: '••••••••',
                      hintStyle: GoogleFonts.inter(color: AppColors.mutedForeground),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.mutedForeground,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Password is required';
                      if (value.trim().length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password
                  Text(
                    'Confirm Password',
                    style: GoogleFonts.inter(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      hintText: '••••••••',
                      hintStyle: GoogleFonts.inter(color: AppColors.mutedForeground),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.mutedForeground,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Please confirm your password';
                      if (value.trim() != _passwordController.text.trim()) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 36),

                  // Register Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isRegistering ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryForeground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.radius),
                        ),
                        elevation: 0,
                      ),
                      child: _isRegistering
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.primaryForeground,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Create Business Account',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
