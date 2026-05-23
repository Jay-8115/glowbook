import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class ServicesManagementScreen extends StatefulWidget {
  final int salonId;

  const ServicesManagementScreen({super.key, required this.salonId});

  @override
  State<ServicesManagementScreen> createState() => _ServicesManagementScreenState();
}

class _ServicesManagementScreenState extends State<ServicesManagementScreen> {
  List<Service> _services = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final list = await ApiService.getSalonServices(widget.salonId);
      setState(() {
        _services = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteService(int serviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: Text(
          'Delete Service',
          style: GoogleFonts.inter(color: AppColors.foreground, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to permanently delete this service? Outstanding bookings won\'t be affected.',
          style: GoogleFonts.inter(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.foreground)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteService(widget.salonId, serviceId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service deleted successfully', style: GoogleFonts.inter(color: AppColors.primaryForeground)),
          backgroundColor: AppColors.primary,
        ),
      );
      _loadServices();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete service: $e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  void _showServiceFormDialog({Service? service}) {
    final isEdit = service != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: service?.name ?? '');
    final priceController = TextEditingController(text: service?.price.toString() ?? '');
    final durationController = TextEditingController(text: service?.durationMinutes.toString() ?? '30');
    final categoryController = TextEditingController(text: service?.category ?? 'hair');
    final descController = TextEditingController(text: service?.description ?? '');
    bool isActive = service?.isActive ?? true;
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
                isEdit ? 'Edit Service' : 'Add New Service',
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
                        Text('Service Name', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nameController,
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13),
                          decoration: _inputDecoration('e.g. Balayage Highlights'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 14),

                        // Description
                        Text('Description', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: descController,
                          maxLines: 2,
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13),
                          decoration: _inputDecoration('e.g. Freehand painted hair highlights...'),
                        ),
                        const SizedBox(height: 14),

                        // Price & Duration side-by-side
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Price (\$)', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: priceController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13),
                                    decoration: _inputDecoration('e.g. 120.00'),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Required';
                                      if (double.tryParse(v.trim()) == null) return 'Invalid price';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Minutes', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: durationController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13),
                                    decoration: _inputDecoration('e.g. 45'),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Required';
                                      if (int.tryParse(v.trim()) == null) return 'Invalid minutes';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Category
                        Text('Category', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: categoryController,
                          style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13),
                          decoration: _inputDecoration('e.g. hair, nails, makeup, spa'),
                        ),

                        // Active Toggle (Only for edit mode)
                        if (isEdit) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Service Active',
                                style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Switch(
                                value: isActive,
                                activeColor: AppColors.primary,
                                onChanged: (v) {
                                  setDialogState(() {
                                    isActive = v;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
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
                            if (isEdit) {
                              await ApiService.updateService(
                                widget.salonId,
                                service.id,
                                name: nameController.text.trim(),
                                price: double.parse(priceController.text.trim()),
                                durationMinutes: int.parse(durationController.text.trim()),
                                category: categoryController.text.trim(),
                                description: descController.text.trim(),
                                isActive: isActive,
                              );
                            } else {
                              await ApiService.createService(
                                widget.salonId,
                                nameController.text.trim(),
                                double.parse(priceController.text.trim()),
                                int.parse(durationController.text.trim()),
                                categoryController.text.trim(),
                                descController.text.trim(),
                              );
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadServices();
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
                      : Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
          'Services Catalog',
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
            onPressed: () => _showServiceFormDialog(),
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
                          onPressed: _loadServices,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.primaryForeground),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _services.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cut_outlined, color: AppColors.mutedForeground, size: 48),
                          const SizedBox(height: 16),
                          Text('No services created', style: GoogleFonts.inter(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Tap the + icon in top right to create your first service.', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final service = _services[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppColors.radius),
                            border: Border.all(
                              color: service.isActive ? AppColors.border : AppColors.border.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          service.name,
                                          style: GoogleFonts.inter(
                                            color: service.isActive ? AppColors.foreground : AppColors.mutedForeground,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            decoration: service.isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                          ),
                                        ),
                                        if (!service.isActive) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(4)),
                                            child: Text('INACTIVE', style: GoogleFonts.inter(fontSize: 8, color: AppColors.mutedForeground, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (service.description != null && service.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        service.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 11.5),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, color: AppColors.mutedForeground, size: 12),
                                        const SizedBox(width: 4),
                                        Text('${service.durationMinutes} min', style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12)),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(4)),
                                          child: Text(service.category?.toUpperCase() ?? 'HAIR', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${service.price.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppColors.mutedForeground, size: 18),
                                        onPressed: () => _showServiceFormDialog(service: service),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppColors.destructive, size: 18),
                                        onPressed: () => _deleteService(service.id),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
