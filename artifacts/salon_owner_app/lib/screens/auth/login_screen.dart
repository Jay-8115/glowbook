import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoggingIn = true;
      _errorMessage = '';
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.login(_emailController.text.trim(), _passwordController.text.trim());
      
      // Ensure the logged in user is actually an owner
      if (!auth.isOwner) {
        await auth.logout();
        throw Exception('Access denied. This app is for Salon Owners only.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Icon
                  const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.primary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  
                  // App Title & Tagline
                  Text(
                    'GlowBook Business',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.foreground,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Salon Owner Management Suite',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

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
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Sign In button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoggingIn ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryForeground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.radius),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoggingIn
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.primaryForeground,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Go to Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have a salon account? ",
                        style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          'Register Here',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
