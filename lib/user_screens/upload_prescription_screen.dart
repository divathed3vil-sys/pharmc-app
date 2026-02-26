import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../main.dart';
import '../services/draft_order_service.dart';
import '../services/verification_service.dart';
import 'address/saved_addresses_screen.dart';

class PickedImage {
  final String name;
  final int size;
  final Uint8List bytes;
  PickedImage({required this.name, required this.size, required this.bytes});
}

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen>
    with TickerProviderStateMixin {
  // ===== STATE =====
  final ImagePicker _imagePicker = ImagePicker();
  final int _maxImages = 3;

  int _step = 0; // 0..5
  bool _isUploading = false;

  final List<PickedImage> _selectedFiles = [];
  String _selectedPharmacy = 'Any Pharmacy';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  Map<String, dynamic>? _deliveryAddress;
  String _paymentMethod = 'cash';

  // verification status
  String _verificationStatus = 'unverified';
  bool _statusLoading = true;

  final List<Map<String, String>> _pharmacies = [
    {
      'name': 'Any Pharmacy',
      'address': 'We\'ll find the nearest pharmacy',
      'type': 'auto',
    },
    {
      'name': 'City Pharmacy',
      'address': '123 Main Street, Colombo 03',
      'type': 'specific',
    },
    {
      'name': 'HealthPlus Pharmacy',
      'address': '45 Galle Road, Dehiwala',
      'type': 'specific',
    },
  ];

  final List<String> _nameSuggestions = [
    'My Medicine',
    'Mom\'s Medicine',
    'Dad\'s Medicine',
    'Kids',
    'Monthly Refill',
  ];

  bool get _isVerified => _verificationStatus == 'approved';

  // Step completion checks
  bool get _stepOk {
    switch (_step) {
      case 0:
        return _selectedFiles.isNotEmpty;
      case 1:
        return _selectedPharmacy.isNotEmpty;
      case 2:
        return true; // notes optional
      case 3:
        return _nameController.text.trim().isNotEmpty;
      case 4:
        return _deliveryAddress != null;
      case 5:
        return _paymentMethod.isNotEmpty && !_isUploading;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() {
      _statusLoading = true;
    });

    try {
      final status = await VerificationService.getMyVerificationStatus();
      if (!mounted) return;
      setState(() {
        _verificationStatus = status;
        _statusLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verificationStatus = 'unverified';
        _statusLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ===== IMAGE PICKING =====
  void _showImageSourceModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _glassSheet(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 14),
            Text(
              'Add Prescription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_selectedFiles.length} of $_maxImages added',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 18),
            _sourceTile(
              isDark: isDark,
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              subtitle: 'Capture prescription with camera',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            const SizedBox(height: 12),
            _sourceTile(
              isDark: isDark,
              icon: Icons.photo_library_rounded,
              title: 'Choose from Files',
              subtitle: 'Select image from your device',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _pickFromFiles();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade400.withOpacity(0.6),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _glassSheet({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sourceTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.10) : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    if (_selectedFiles.length >= _maxImages) return _showMaxLimitSnackbar();
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedFiles.add(
          PickedImage(name: image.name, size: bytes.length, bytes: bytes),
        );
      });
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _pickFromFiles() async {
    if (_selectedFiles.length >= _maxImages) return _showMaxLimitSnackbar();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return;

      final remaining = _maxImages - _selectedFiles.length;
      for (final file in result.files.take(remaining)) {
        if (file.bytes == null) continue;
        setState(() {
          _selectedFiles.add(
            PickedImage(name: file.name, size: file.size, bytes: file.bytes!),
          );
        });
      }
    } catch (e) {
      debugPrint('File error: $e');
    }
  }

  void _showMaxLimitSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maximum $_maxImages prescriptions allowed'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ===== ADDRESS PICK =====
  Future<void> _selectAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SavedAddressesScreen(selectMode: true),
      ),
    );
    if (result != null) {
      setState(() => _deliveryAddress = result);
    }
  }

  // ===== NAV =====
  void _next() {
    if (!_stepOk) return;
    if (_step < 5) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  // ===== SUBMIT =====
  Future<void> _submitOrSaveDraft() async {
    if (!_stepOk) return;

    final user = supabase.auth.currentUser;
    if (user == null) {
      _snack('Please login first.', isError: true);
      return;
    }

    setState(() => _isUploading = true);
    try {
      if (!_isVerified) {
        await _saveDraftLocally(user.id);
        if (!mounted) return;
        await _showDraftSavedDialog();
        return;
      }

      await _submitOrderToSupabase(user.id);
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveDraftLocally(String userId) async {
    // one local address only (as you requested)
    final addr = DraftAddress(
      label: (_deliveryAddress?['label'] ?? 'Home').toString(),
      addressLine: (_deliveryAddress?['address_line'] ?? '').toString(),
      latitude: ((_deliveryAddress?['latitude'] ?? 0) as num).toDouble(),
      longitude: ((_deliveryAddress?['longitude'] ?? 0) as num).toDouble(),
    );
    await DraftOrderService.saveDraftAddress(addr);

    final draft = DraftOrder(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      orderName: _nameController.text.trim(),
      pharmacyName: _selectedPharmacy,
      notes: _notesController.text.trim(),
      paymentMethod: _paymentMethod,
      address: addr,
      images: _selectedFiles
          .map((f) => DraftImage(name: f.name, size: f.size, bytes: f.bytes))
          .toList(),
      createdAt: DateTime.now(),
    );

    await DraftOrderService.addDraftOrder(draft);
  }

  Future<void> _submitOrderToSupabase(String userId) async {
    final orderResponse = await supabase
        .from('orders')
        .insert({
          'user_id': userId,
          'order_name': _nameController.text.trim(),
          'pharmacy_name': _selectedPharmacy,
          'pharmacy_address': _selectedPharmacy == 'Any Pharmacy'
              ? 'Auto-assigned'
              : 'Selected',
          'status': 'order_placed',
          'notes': _notesController.text.trim(),
          'delivery_address_id': _deliveryAddress!['id'],
          'payment_method': _paymentMethod,
          'total_price': 0.00,
        })
        .select()
        .single();

    final orderId = orderResponse['id'];

    for (final file in _selectedFiles) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = '$userId/$fileName';
      await supabase.storage
          .from('prescriptions')
          .uploadBinary(filePath, file.bytes);
      await supabase.from('prescription_images').insert({
        'order_id': orderId,
        'image_url': filePath,
        'file_name': file.name,
      });
    }

    await supabase.from('order_status_history').insert({
      'order_id': orderId,
      'status': 'order_placed',
      'changed_by': userId,
      'note': 'Order placed: ${_nameController.text.trim()}',
    });

    _showSuccessDialog(orderId);
  }

  Future<void> _showDraftSavedDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_clock_rounded,
                  color: Colors.orange.shade600,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Saved as Draft',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can explore the app, but orders will be uploaded after your account is verified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String orderId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shortId = orderId.toString().substring(0, 8).toUpperCase();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.green.shade600,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Order Placed!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your prescription is being reviewed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#ORD-$shortId',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: isDark ? Colors.grey.shade200 : Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Order',
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            onPressed: _loadVerificationStatus,
            icon: Icon(Icons.refresh_rounded, color: sub),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopStatusBanner(isDark, text, sub),
            const SizedBox(height: 10),
            _buildStepHeader(isDark, text, sub),
            const SizedBox(height: 12),
            Expanded(child: _buildStepBody(isDark, text, sub)),
            _buildBottomBar(isDark, text),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStatusBanner(bool isDark, Color text, Color sub) {
    if (_statusLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _glassCard(
          isDark: isDark,
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.teal.shade500,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Checking verification status...',
                style: TextStyle(color: sub, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (_isVerified) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _glassCard(
          isDark: isDark,
          child: Row(
            children: [
              Icon(
                Icons.verified_rounded,
                color: Colors.green.shade500,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Verified account — orders will be processed immediately',
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _glassCard(
        isDark: isDark,
        child: Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: Colors.orange.shade500,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Unverified — placing an order will save a draft until verification',
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(bool isDark, Color text, Color sub) {
    final titles = [
      'Upload Prescriptions',
      'Choose Pharmacy',
      'Add Notes (Optional)',
      'Name this Order',
      'Delivery Address',
      'Payment Method',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _glassCard(
        isDark: isDark,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.teal.shade600.withOpacity(isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${_step + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.teal.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titles[_step],
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Step ${_step + 1} of 6',
                    style: TextStyle(color: sub, fontSize: 12),
                  ),
                ],
              ),
            ),
            _progressPills(isDark),
          ],
        ),
      ),
    );
  }

  Widget _progressPills(bool isDark) {
    return Row(
      children: List.generate(6, (i) {
        final active = i <= _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(left: 4),
          width: active ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? Colors.teal.shade500
                : (isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }

  Widget _buildStepBody(bool isDark, Color text, Color sub) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: Padding(
        key: ValueKey(_step),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _glassCard(
          isDark: isDark,
          child: _buildStepContent(isDark, text, sub),
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isDark, Color text, Color sub) {
    switch (_step) {
      case 0:
        return _stepPrescriptions(isDark, text, sub);
      case 1:
        return _stepPharmacy(isDark, text, sub);
      case 2:
        return _stepNotes(isDark, text, sub);
      case 3:
        return _stepName(isDark, text, sub);
      case 4:
        return _stepAddress(isDark, text, sub);
      case 5:
        return _stepPayment(isDark, text, sub);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _stepPrescriptions(bool isDark, Color text, Color sub) {
    final border = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload up to $_maxImages images',
          style: TextStyle(color: sub, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        if (_selectedFiles.isNotEmpty) _imageGrid(isDark),
        if (_selectedFiles.length < _maxImages)
          GestureDetector(
            onTap: _showImageSourceModal,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border, width: 1.2),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFiles.isEmpty
                        ? Icons.cloud_upload_outlined
                        : Icons.add_photo_alternate_outlined,
                    size: 36,
                    color: sub,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFiles.isEmpty
                        ? 'Upload prescription'
                        : 'Add another',
                    style: TextStyle(fontWeight: FontWeight.w800, color: text),
                  ),
                  const SizedBox(height: 4),
                  Text('Camera or Files', style: TextStyle(color: sub)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _imageGrid(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _selectedFiles.asMap().entries.map((entry) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                entry.value.bytes,
                width: 105,
                height: 105,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => setState(() => _selectedFiles.removeAt(entry.key)),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _stepPharmacy(bool isDark, Color text, Color sub) {
    return Column(
      children: _pharmacies.map((p) {
        final selected = _selectedPharmacy == p['name'];
        final isAuto = p['type'] == 'auto';

        return GestureDetector(
          onTap: () => setState(() => _selectedPharmacy = p['name']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: selected
                  ? (isAuto
                        ? Colors.blue.withOpacity(isDark ? 0.18 : 0.10)
                        : Colors.teal.withOpacity(isDark ? 0.18 : 0.10))
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? (isAuto ? Colors.blue.shade400 : Colors.teal.shade400)
                    : (isDark
                          ? Colors.white.withOpacity(0.10)
                          : Colors.black.withOpacity(0.06)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? (isAuto
                              ? Colors.blue.withOpacity(0.16)
                              : Colors.teal.withOpacity(0.16))
                        : (isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.04)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isAuto
                        ? Icons.near_me_rounded
                        : Icons.local_pharmacy_rounded,
                    color: selected
                        ? (isAuto ? Colors.blue.shade300 : Colors.teal.shade300)
                        : sub,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name']!,
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p['address']!,
                        style: TextStyle(color: sub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: Colors.teal.shade400),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _stepNotes(bool isDark, Color text, Color sub) {
    final inputBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.03);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optional',
          style: TextStyle(color: sub, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            style: TextStyle(color: text),
            decoration: InputDecoration(
              hintText: 'e.g. Only need tablets, not syrup',
              hintStyle: TextStyle(color: sub),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepName(bool isDark, Color text, Color sub) {
    final inputBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.03);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Give it a short name',
          style: TextStyle(color: sub, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: _nameController,
            style: TextStyle(color: text),
            decoration: InputDecoration(
              hintText: 'e.g. Mom\'s Medicine',
              hintStyle: TextStyle(color: sub),
              prefixIcon: Icon(Icons.edit_rounded, color: sub),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _nameSuggestions.map((name) {
            final selected = _nameController.text == name;
            return GestureDetector(
              onTap: () => setState(() => _nameController.text = name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.teal.withOpacity(isDark ? 0.25 : 0.12)
                      : (isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: selected ? Colors.teal.shade400 : Colors.transparent,
                  ),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.teal.shade300 : sub,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _stepAddress(bool isDark, Color text, Color sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select one address',
          style: TextStyle(color: sub, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectAddress,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _deliveryAddress != null
                    ? Colors.teal.shade400.withOpacity(0.6)
                    : (isDark
                          ? Colors.white.withOpacity(0.10)
                          : Colors.black.withOpacity(0.06)),
              ),
              color: _deliveryAddress != null
                  ? Colors.teal.withOpacity(isDark ? 0.12 : 0.06)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _deliveryAddress != null
                        ? Icons.location_on_rounded
                        : Icons.add_location_alt_rounded,
                    color: _deliveryAddress != null
                        ? Colors.teal.shade300
                        : sub,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _deliveryAddress == null
                      ? Text(
                          'Select delivery address',
                          style: TextStyle(
                            color: sub,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_deliveryAddress!['label'] ?? 'Address')
                                  .toString(),
                              style: TextStyle(
                                color: text,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (_deliveryAddress!['address_line'] ?? '')
                                  .toString(),
                              style: TextStyle(color: sub, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),
                Icon(Icons.chevron_right_rounded, color: sub),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepPayment(bool isDark, Color text, Color sub) {
    Widget opt({
      required String title,
      required String subtitle,
      required String value,
      required IconData icon,
      required bool enabled,
    }) {
      final selected = _paymentMethod == value && enabled;
      return GestureDetector(
        onTap: enabled
            ? () => setState(() => _paymentMethod = value)
            : () => _snack('Online payment coming soon'),
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? Colors.teal.shade400
                    : (isDark
                          ? Colors.white.withOpacity(0.10)
                          : Colors.black.withOpacity(0.06)),
              ),
              color: selected
                  ? Colors.teal.withOpacity(isDark ? 0.18 : 0.10)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.teal.shade300 : sub,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: sub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: Colors.teal.shade400),
                if (!enabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Soon',
                      style: TextStyle(
                        color: sub,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        opt(
          title: 'Cash on Delivery',
          subtitle: 'Pay when medicine arrives',
          value: 'cash',
          icon: Icons.payments_rounded,
          enabled: true,
        ),
        opt(
          title: 'Card / Online',
          subtitle: 'Coming soon',
          value: 'card',
          icon: Icons.credit_card_rounded,
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDark, Color text) {
    final canGoBack = _step > 0;
    final isLast = _step == 5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          if (canGoBack)
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _isUploading ? null : _back,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.08),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          if (canGoBack) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (!_stepOk || _isUploading)
                    ? null
                    : (isLast ? _submitOrSaveDraft : _next),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  disabledBackgroundColor: isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.grey.shade200,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isLast
                            ? (_isVerified ? 'Place Order' : 'Save Draft')
                            : 'Next',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
