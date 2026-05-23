import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class SalonFormScreen extends StatefulWidget {
  final Salon? salon;

  const SalonFormScreen({super.key, this.salon});

  @override
  State<SalonFormScreen> createState() => _SalonFormScreenState();
}

class _SalonFormScreenState extends State<SalonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _imageController;
  late TextEditingController _openTimeController;
  late TextEditingController _closeTimeController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.salon?.name ?? '');
    _addressController = TextEditingController(text: widget.salon?.address ?? '');
    _cityController = TextEditingController(text: widget.salon?.city ?? '');
    _descriptionController = TextEditingController(text: widget.salon?.description ?? '');
    _phoneController = TextEditingController(text: widget.salon?.phone ?? '');
    _imageController = TextEditingController(text: widget.salon?.imageUrl ?? '');
    _openTimeController = TextEditingController(text: widget.salon?.openTime ?? '09:00');
    _closeTimeController = TextEditingController(text: widget.salon?.closeTime ?? '21:00');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _imageController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveSalon() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.salon != null) {
        // Update
        await ApiService.updateSalon(
          widget.salon!.id,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          description: _descriptionController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          imageUrl: _imageController.text.trim().isEmpty ? null : _imageController.text.trim(),
          openTime: _openTimeController.text.trim(),
          closeTime: _closeTimeController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Salon profile updated successfully', style: GoogleFonts.inter(color: AppColors.primaryForeground)),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        // Create
        await ApiService.createSalon(
          _nameController.text.trim(),
          _addressController.text.trim(),
          _cityController.text.trim(),
          _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          _imageController.text.trim().isEmpty ? null : _imageController.text.trim(),
          _openTimeController.text.trim(),
          _closeTimeController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Salon profile created successfully', style: GoogleFonts.inter(color: AppColors.primaryForeground)),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save salon: ${e.toString().replaceAll("Exception: ", "")}', style: GoogleFonts.inter()),
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
    final isEdit = widget.salon != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Update Salon Details' : 'Create Salon Profile',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Salon Name
              Text(
                'Salon Name',
                style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                decoration: _inputDecoration('e.g. Bella Vita Hair Salon'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Salon name is required' : null,
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                'About Description',
                style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13),
                decoration: _inputDecoration('e.g. Premium hair styling and boutique spa treatments...'),
              ),
              const SizedBox(height: 20),

              // Address
              Text(
                'Street Address',
                style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                decoration: _inputDecoration('e.g. 123 Luxury Ave, Suite B'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Street address is required' : null,
              ),
              const SizedBox(height: 20),

              // City
              Text(
                'City',
                style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cityController,
                style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                decoration: _inputDecoration('e.g. New York'),
                validator: (val) => val == null || val.trim().isEmpty ? 'City is required' : null,
              ),
              const SizedBox(height: 20),

              // Phone
              Text(
                'Contact Phone',
                style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                decoration: _inputDecoration('e.g. +1 555-0199'),
              ),
              const SizedBox(height: 20),

              // Image Url
              Text(
                'Salon Image Link',
                style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageController,
                style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                decoration: _inputDecoration('e.g. https://images.unsplash.com/...'),
              ),
              const SizedBox(height: 20),

              // Hours: Open time & Close time in side-by-side row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Opening Hour',
                          style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _openTimeController,
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                          decoration: _inputDecoration('e.g. 09:00'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Closing Hour',
                          style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _closeTimeController,
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 14),
                          decoration: _inputDecoration('e.g. 21:00'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Action submit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSalon,
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
                          isEdit ? 'Update Details' : 'Create Profile',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.card,
      hintText: hint,
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
    );
  }
}
