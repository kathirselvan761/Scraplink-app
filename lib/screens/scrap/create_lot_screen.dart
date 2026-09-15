import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/material_price_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lot_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/location_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/loading_overlay.dart';
import 'lot_detail_screen.dart';

class CreateLotScreen extends StatefulWidget {
  const CreateLotScreen({super.key});

  @override
  State<CreateLotScreen> createState() => _CreateLotScreenState();
}

class _CreateLotScreenState extends State<CreateLotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _locationService = LocationService();

  MaterialPriceModel? _selectedMaterial;
  File? _selectedImage;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  String? _locationError;
  bool _isLocationPermanentlyDenied = false;
  double _calculatedPayout = 0.0;

  bool get _hasUnsavedData =>
      _selectedMaterial != null ||
      _weightController.text.trim().isNotEmpty ||
      _selectedImage != null ||
      _notesController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LotProvider>().loadMaterialPrices();
      _fetchLocation();
    });
    _weightController.addListener(_updatePayout);
  }

  @override
  void dispose() {
    _weightController.removeListener(_updatePayout);
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updatePayout() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final price = _selectedMaterial?.pricePerKg ?? 0.0;
    setState(() {
      _calculatedPayout = weight * price;
    });
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
      _isLocationPermanentlyDenied = false;
    });

    try {
      final status = await Permission.location.request();
      if (status.isPermanentlyDenied) {
        setState(() {
          _isLocationPermanentlyDenied = true;
          _locationError = 'Location permission is permanently denied. Please enable it in device settings.';
          _isLoadingLocation = false;
        });
        return;
      }

      final pos = await _locationService.getCurrentPosition();
      final double? lat = pos['latitude'];
      final double? lng = pos['longitude'];

      setState(() {
        _latitude = lat;
        _longitude = lng;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = e.toString().replaceAll('Exception: ', '');
        _isLoadingLocation = false;
      });
    }
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      _showSettingsDialog('Camera permission is required to take photos of scrap lots.');
      return false;
    }
    return status.isGranted;
  }

  void _showSettingsDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) return;
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        imageQuality: 75,
      );

      if (picked != null) {
        final file = File(picked.path);
        final bytes = await file.length();

        // Cap file size at 1MB
        if (bytes > 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size exceeds 1MB limit. Please select a smaller photo.'),
                backgroundColor: AppTheme.errorRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImage = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: ${e.toString()}')),
        );
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _weightController.clear();
    _notesController.clear();
    setState(() {
      _selectedMaterial = null;
      _selectedImage = null;
      _calculatedPayout = 0.0;
    });
    _fetchLocation();
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedData) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard Unsaved Scrap Lot?'),
        content: const Text(
          'You have entered scrap details. If you leave now, your changes will be discarded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  Future<void> _handleSubmit() async {
    // 1. Connectivity check
    final isOnline = await ConnectivityService().checkConnection();
    if (!mounted) return;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet. Please try again when connected.'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Form validation (weight)
    if (!_formKey.currentState!.validate()) return;

    // 3. Material validation
    if (_selectedMaterial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a material type'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // 4. Image validation
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a photo of the scrap'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // 5. Location validation
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable and acquire your location before submitting'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    print('SUBMIT: material=${_selectedMaterial?.material}');
    print('SUBMIT: weight text=${_weightController.text}');
    final weight = double.tryParse(_weightController.text.trim());
    print('SUBMIT: parsed weight=$weight (type: ${weight.runtimeType})');
    print('SUBMIT: lat=$_latitude (type: ${_latitude.runtimeType})');
    print('SUBMIT: lng=$_longitude (type: ${_longitude.runtimeType})');
    print('SUBMIT: imageFile=${_selectedImage?.path}');

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid weight greater than 0'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final lat = _latitude!.toDouble();
    final lng = _longitude!.toDouble();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    print('SUBMIT: collector_id=$userId');

    final lotProvider = context.read<LotProvider>();

    final createdLot = await lotProvider.createLot(
      material: _selectedMaterial!.material,
      weight: weight,
      collectorId: userId,
      lat: lat,
      lng: lng,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      imageFile: _selectedImage,
    );

    if (!mounted) return;

    if (createdLot != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 28),
              SizedBox(width: 10),
              Text('Lot Created!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your scrap lot has been successfully registered with the system.'),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0x1A2E7D32),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lot ID: ${createdLot.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _resetForm();
              },
              child: const Text('Add Another'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => LotDetailScreen(lotId: createdLot.id),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View Lot'),
            ),
          ],
        ),
      );
    } else {
      final errorMsg = lotProvider.errorMessage ?? 'Failed to create scrap lot. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lotProvider = context.watch<LotProvider>();
    final materials = lotProvider.materialPrices;
    final isLoading = lotProvider.isLoading;

    return PopScope(
      canPop: !_hasUnsavedData,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _confirmDiscard();
        if (canLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Scrap Lot'),
        ),
        body: LoadingOverlay(
          isLoading: isLoading,
          message: 'Uploading scrap lot...',
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Material Dropdown
                  const Text(
                    'Scrap Material',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<MaterialPriceModel>(
                    initialValue: _selectedMaterial,
                    isExpanded: true,
                    hint: const Text('Select Material Type'),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: materials.map((m) {
                      return DropdownMenuItem<MaterialPriceModel>(
                        value: m,
                        child: Text('${m.material} (₹${m.pricePerKg.toStringAsFixed(2)}/kg)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedMaterial = val;
                        _updatePayout();
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Estimated Weight
                  const Text(
                    'Estimated Weight (kg)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 25.5',
                      suffixText: 'kg',
                      prefixIcon: Icon(Icons.scale_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter the estimated weight';
                      }
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Weight must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 3. Photo Section (1MB capped compression)
                  const Text(
                    'Scrap Photo',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Take Photo'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 12),
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _selectedImage = null),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // 4. Location Section with Permission Handling
                  const Text(
                    'Collection Location',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (_locationError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off, color: AppTheme.errorRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _locationError!,
                              style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                            ),
                          ),
                          if (_isLocationPermanentlyDenied)
                            const TextButton(
                              onPressed: openAppSettings,
                              child: Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                            )
                          else
                            TextButton(
                              onPressed: _fetchLocation,
                              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location, color: AppTheme.primaryGreen),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isLoadingLocation
                                ? const Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      SizedBox(width: 10),
                                      Text('Acquiring GPS coordinates...'),
                                    ],
                                  )
                                : Text(
                                    _latitude != null && _longitude != null
                                        ? 'Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}'
                                        : 'No coordinates acquired',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Refresh Location',
                            onPressed: _isLoadingLocation ? null : _fetchLocation,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 5. Notes Section
                  const Text(
                    'Notes (Optional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Packed in 2 burlap bags, ground floor pickup',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6. Estimated Payout Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x1A2E7D32),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x4D2E7D32)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated Payout',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Based on current market rate',
                              style: TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                          ],
                        ),
                        Text(
                          '₹${_calculatedPayout.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 7. Submit Button
                  PrimaryButton(
                    text: 'Submit Scrap Lot',
                    onPressed: _handleSubmit,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
