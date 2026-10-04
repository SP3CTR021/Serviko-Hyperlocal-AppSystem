import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';

void showProfileCompletionModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ProfileCompletionModalContent(),
  );
}

class _ProfileCompletionModalContent extends StatefulWidget {
  const _ProfileCompletionModalContent();

  @override
  State<_ProfileCompletionModalContent> createState() => _ProfileCompletionModalContentState();
}

class _ProfileCompletionModalContentState extends State<_ProfileCompletionModalContent> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _barangayCtrl;
  late TextEditingController _idNumberCtrl;

  String _selectedIdType = 'PhilSys National ID';
  String? _profilePhotoUrl;
  String? _idPhotoUrl;

  bool _isUploadingPhoto = false;
  bool _isUploadingId = false;
  bool _isSubmitting = false;

  final List<String> _idTypes = [
    'PhilSys National ID',
    'Driver\'s License',
    'Passport',
    'UMID / SSS ID',
    'Postal ID',
    'PRC ID',
    'Voter\'s ID',
    'Barangay ID',
  ];

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    _cityCtrl = TextEditingController(text: user?.city ?? '');
    _barangayCtrl = TextEditingController(text: user?.barangay ?? '');
    _idNumberCtrl = TextEditingController(text: user?.idNumber ?? '');
    _selectedIdType = user?.idType ?? 'PhilSys National ID';
    _profilePhotoUrl = user?.profilePhotoUrl;
    _idPhotoUrl = user?.idPhotoUrl;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _barangayCtrl.dispose();
    _idNumberCtrl.dispose();
    super.dispose();
  }

  int _calculateCurrentProgress() {
    int progress = 30; // Base: Name + Email
    if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) progress += 15;
    if (_phoneCtrl.text.trim().isNotEmpty) progress += 15;
    if (_cityCtrl.text.trim().isNotEmpty || _barangayCtrl.text.trim().isNotEmpty) progress += 15;
    if (_idNumberCtrl.text.trim().isNotEmpty) {
      progress += 25;
    }
    return progress.clamp(0, 100);
  }

  Future<void> _handlePickProfilePhoto() async {
    setState(() => _isUploadingPhoto = true);
    try {
      final result = await CloudinaryService().pickAndUploadImage(
        source: ImageSource.gallery,
        folder: 'serviko/profile_photos',
      );
      if (result != null) {
        setState(() {
          _profilePhotoUrl = result.url;
        });
        await AuthService().updateProfilePhoto(result.url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _handlePickIdPhoto() async {
    setState(() => _isUploadingId = true);
    try {
      final result = await CloudinaryService().pickAndUploadImage(
        source: ImageSource.gallery,
        folder: 'serviko/id_verification',
      );
      if (result != null) {
        setState(() {
          _idPhotoUrl = result.url;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ID upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingId = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // ID photo is optional for now; ID number is required and validated by the form
    setState(() => _isSubmitting = true);

    try {
      final success = await AuthService().submitVerification(
        idType: _selectedIdType,
        idNumber: _idNumberCtrl.text.trim(),
        idPhotoUrl: _idPhotoUrl,
        phoneNumber: _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        barangay: _barangayCtrl.text.trim(),
        profilePhotoUrl: _profilePhotoUrl,
      );

      if (mounted) {
        Navigator.pop(context);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile verified successfully! All features are now unlocked.'),
              backgroundColor: AppTheme.sbGreen,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification submission error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateCurrentProgress();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            // Header Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.sbGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.sbGreen.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppTheme.sbGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete Profile & Verify ID',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.sbInk,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Unlock booking, job posting & all features',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.sbInkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.sbInkSoft),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Progress Bar Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profile Progress',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.sbInk,
                          ),
                        ),
                        Text(
                          '$progress% Completed',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.sbGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress / 100.0,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.sbGreen),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '🔒 Required: Valid Government ID Number & info are needed to verify your account. (Photo is optional for now)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.sbInk,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: AppTheme.sbLine),

            // Form Fields Scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Profile Photo
                      const Text(
                        '1. Profile Photo',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.sbInk),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF1F5F9),
                              border: Border.all(color: AppTheme.sbLine, width: 2),
                              image: _profilePhotoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_profilePhotoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profilePhotoUrl == null
                                ? const Icon(Icons.person_rounded, color: AppTheme.sbInkSoft, size: 32)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _isUploadingPhoto ? null : _handlePickProfilePhoto,
                                  icon: _isUploadingPhoto
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.camera_alt_outlined, size: 16),
                                  label: Text(_profilePhotoUrl != null ? 'Change Photo' : 'Upload Photo'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.sbInk,
                                    side: const BorderSide(color: AppTheme.sbLine),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Clear face portrait helps build trust with users',
                                  style: TextStyle(fontSize: 11, color: AppTheme.sbInkSoft),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 2: Contact Number
                      const Text(
                        '2. Contact Information',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.sbInk),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Phone number is required';
                          if (val.trim().length < 10) return 'Please enter a valid phone number';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Mobile Phone Number *',
                          hintText: '0917-123-4567',
                          prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Location Fields
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityCtrl,
                              onChanged: (_) => setState(() {}),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'City is required' : null,
                              decoration: InputDecoration(
                                labelText: 'City / Municipality *',
                                hintText: 'Davao City',
                                prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _barangayCtrl,
                              onChanged: (_) => setState(() {}),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Barangay required' : null,
                              decoration: InputDecoration(
                                labelText: 'Barangay *',
                                hintText: 'Matina',
                                prefixIcon: const Icon(Icons.signpost_rounded, size: 20),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 3: Government ID Verification
                      const Text(
                        '3. Government ID Verification',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.sbInk),
                      ),
                      const SizedBox(height: 8),

                      // ID Type dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedIdType,
                        items: _idTypes
                            .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedIdType = val);
                        },
                        decoration: InputDecoration(
                          labelText: 'Government ID Type *',
                          prefixIcon: const Icon(Icons.badge_rounded, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ID Number
                      TextFormField(
                        controller: _idNumberCtrl,
                        onChanged: (_) => setState(() {}),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'ID Number is required' : null,
                        decoration: InputDecoration(
                          labelText: 'ID / Document Number *',
                          hintText: 'e.g. 1234-5678-9012',
                          prefixIcon: const Icon(Icons.pin_rounded, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ID Document Photo Upload Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _idPhotoUrl != null ? AppTheme.sbGreen : const Color(0xFFCBD5E1),
                            width: _idPhotoUrl != null ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _idPhotoUrl != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                                  color: _idPhotoUrl != null ? AppTheme.sbGreen : const Color(0xFF64748B),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _idPhotoUrl != null ? 'Government ID Uploaded' : 'Upload Front of ID Card (Optional)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _idPhotoUrl != null ? AppTheme.sbGreen : AppTheme.sbInk,
                                    ),
                                  ),
                                ),
                                if (_idPhotoUrl != null)
                                  const Text(
                                    'Ready',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.sbGreen),
                                  ),
                              ],
                            ),
                            if (_idPhotoUrl != null) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _idPhotoUrl!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _isUploadingId ? null : _handlePickIdPhoto,
                              icon: _isUploadingId
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Icon(_idPhotoUrl != null ? Icons.refresh_rounded : Icons.camera_alt_outlined, size: 16),
                              label: Text(_idPhotoUrl != null ? 'Re-upload ID Photo' : 'Select ID Photo (Optional)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.sbInk,
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.sbGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Verify & Unlock Account',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Your data is securely encrypted under Philippine Data Privacy standards.',
                          style: TextStyle(fontSize: 11, color: AppTheme.sbInkSoft),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
