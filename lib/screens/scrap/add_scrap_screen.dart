import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_exception.dart';
import '../../models/material_item.dart';
import '../../models/scrap.dart';
import '../../repositories/auth_repository.dart';
import '../../services/material_service.dart';
import '../../services/scrap_service.dart';
import 'digital_receipt_screen.dart';

/// Screen guiding the Collector through the step-by-step Scrap Entry process:
/// 1. E-Waste Photo ➔ 2. Material Selection ➔ 3. Weight & Pricing ➔ 4. Notes ➔ 5. Review & Submit
class AddScrapScreen extends StatefulWidget {
  const AddScrapScreen({super.key});

  @override
  State<AddScrapScreen> createState() => _AddScrapScreenState();
}

class _AddScrapScreenState extends State<AddScrapScreen> {
  final MaterialService _materialService = MaterialService();
  final ScrapService _scrapService = ScrapService();
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0; // 0: Photo, 1: Material, 2: Weight & Price, 3: Review
  XFile? _selectedImage;
  String? _selectedMaterial;
  double _pricePerKg = 0.0;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<MaterialItem> _availableMaterials = [];
  bool _isLoadingMaterials = true;
  bool _isSubmitting = false;
  double _calculatedPrice = 0.0;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
    _weightController.addListener(_onWeightChanged);
  }

  @override
  void dispose() {
    _weightController.removeListener(_onWeightChanged);
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    try {
      final materials = await _materialService.getActiveMaterials();
      if (mounted) {
        setState(() {
          _availableMaterials = materials;
          if (_availableMaterials.isNotEmpty) {
            _selectedMaterial = _availableMaterials.first.material;
            _pricePerKg = _availableMaterials.first.pricePerKg;
          }
          _isLoadingMaterials = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _availableMaterials = MaterialItem.defaultMaterials;
          _selectedMaterial = _availableMaterials.first.material;
          _pricePerKg = _availableMaterials.first.pricePerKg;
          _isLoadingMaterials = false;
        });
      }
    }
  }

  void _onWeightChanged() {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    setState(() {
      _calculatedPrice = double.parse((weight * _pricePerKg).toStringAsFixed(2));
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
          _formError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _formError = 'Failed to capture photo: $e';
        });
      }
    }
  }

  Future<void> _submitScrap() async {
    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final weightVal = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final collector = AuthRepository.instance.currentCollector;

    try {
      final Scrap createdScrap = await _scrapService.createScrapLot(
        material: _selectedMaterial ?? 'E-waste',
        weight: weightVal,
        estimatedPrice: _calculatedPrice,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        collectorId: collector?.id,
        imagePath: _selectedImage?.path,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // Navigate immediately to Digital Receipt displaying canonical backend Scrap ID
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DigitalReceiptScreen(
              scrap: createdScrap,
              localImageFile: _selectedImage != null ? File(_selectedImage!.path) : null,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _formError = e.userFriendlyMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _formError = 'Failed to submit scrap: $e';
        });
      }
    }
  }

  void _nextStep() {
    setState(() {
      _formError = null;
    });

    if (_currentStep == 0) {
      if (_selectedImage == null) {
        setState(() {
          _formError = 'Please take or upload an E-Waste photo before proceeding.';
        });
        return;
      }
    } else if (_currentStep == 1) {
      if (_selectedMaterial == null || _selectedMaterial!.isEmpty) {
        setState(() {
          _formError = 'Please select a scrap material category.';
        });
        return;
      }
    } else if (_currentStep == 2) {
      final weight = double.tryParse(_weightController.text.trim());
      if (weight == null || weight <= 0) {
        setState(() {
          _formError = 'Please enter a valid positive weight in kg.';
        });
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _formError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add New Scrap',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Step Progress Bar
          _buildStepTracker(),

          // Error Message Area
          if (_formError != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formError!,
                      style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Main Step Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepContent(),
            ),
          ),

          // Bottom Navigation Buttons
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepTracker() {
    final stepLabels = ['Photo', 'Material', 'Weight', 'Review'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Row(
        children: List.generate(stepLabels.length * 2 - 1, (index) {
          if (index.isOdd) {
            final lineIndex = index ~/ 2;
            final isCompleted = _currentStep > lineIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF334155),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCompleted = _currentStep > stepIndex;
          final isCurrent = _currentStep == stepIndex;

          return Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : (isCurrent ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFF0F172A)),
                  border: Border.all(
                    color: (isCompleted || isCurrent) ? const Color(0xFF10B981) : const Color(0xFF475569),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isCurrent ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stepLabels[stepIndex],
                style: TextStyle(
                  color: isCurrent ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPhotoStep();
      case 1:
        return _buildMaterialStep();
      case 2:
        return _buildWeightStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: E-WASTE PHOTO UPLOAD
  Widget _buildPhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Upload E-Waste Photo',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Capture or select a clear image of the scrap material for inspection and identification.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const SizedBox(height: 20),

        if (_selectedImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_selectedImage!.path),
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155), style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF10B981), size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No scrap photo selected yet',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Take a photo or choose from gallery',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Choose Gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF475569)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 2: MATERIAL SELECTION
  Widget _buildMaterialStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Select Scrap Material',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select from the active material catalog configured in the existing backend.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const SizedBox(height: 20),

        if (_isLoadingMaterials)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _availableMaterials.map((mat) {
              final isSelected = _selectedMaterial?.toLowerCase() == mat.material.toLowerCase();
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedMaterial = mat.material;
                    _pricePerKg = mat.pricePerKg;
                    _onWeightChanged();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF10B981) : const Color(0xFF334155),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mat.material,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '₹${mat.pricePerKg.toStringAsFixed(0)} / kg',
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // STEP 3: WEIGHT & PRICING
  Widget _buildWeightStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Enter Weight & Notes',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Enter the measured or estimated weight in kilograms.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Material Badge
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.category_outlined, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _selectedMaterial ?? 'E-waste',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Text(
                'Rate: ₹${_pricePerKg.toStringAsFixed(0)}/kg',
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Weight Input
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Weight (Kilograms)',
            labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
            suffixText: 'kg',
            suffixStyle: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16),
            prefixIcon: const Icon(Icons.scale_outlined, color: Color(0xFF10B981)),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Live Calculated Estimate Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withValues(alpha: 0.15),
                const Color(0xFF1E293B),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated Value', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  SizedBox(height: 2),
                  Text('Calculated via backend rate', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                ],
              ),
              Text(
                '₹${_calculatedPrice.toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Optional Notes
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Collection Notes (Optional)',
            hintText: 'e.g. Pickup site details, hardware condition, etc.',
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.note_alt_outlined, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 4: REVIEW & SUBMIT
  Widget _buildReviewStep() {
    final collector = AuthRepository.instance.currentCollector;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 4: Review Scrap Details',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Confirm all information below before transmitting to ScrapLink Backend.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const SizedBox(height: 16),

        // Photo Thumbnail
        if (_selectedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(_selectedImage!.path),
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),

        const SizedBox(height: 16),

        // Specs Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            children: [
              _buildReviewRow('Collector', collector?.name ?? 'Assigned Collector'),
              _buildReviewRow('Material', _selectedMaterial ?? 'E-waste'),
              _buildReviewRow('Estimated Weight', '${weight.toStringAsFixed(2)} kg'),
              _buildReviewRow('Rate per kg', '₹${_pricePerKg.toStringAsFixed(2)}'),
              _buildReviewRow('Estimated Value', '₹${_calculatedPrice.toStringAsFixed(2)}', isHighlight: true),
              if (_notesController.text.trim().isNotEmpty)
                _buildReviewRow('Notes', _notesController.text.trim()),
            ],
          ),
        ),

        const SizedBox(height: 14),

        const Row(
          children: [
            Icon(Icons.verified_outlined, color: Color(0xFF10B981), size: 16),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'A canonical sequential Scrap ID will be generated upon submission.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isHighlight ? const Color(0xFF10B981) : Colors.white,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                fontSize: isHighlight ? 15 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 3,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF475569)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 5,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : (isLastStep ? _submitScrap : _nextStep),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(isLastStep ? Icons.cloud_upload_outlined : Icons.arrow_forward, size: 18),
              label: Text(
                _isSubmitting
                    ? 'Submitting...'
                    : (isLastStep ? 'Submit Scrap' : 'Next Step'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
