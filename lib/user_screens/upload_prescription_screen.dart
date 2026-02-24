import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../main.dart';
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

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  final List<PickedImage> _selectedFiles = [];
  final int _maxImages = 3;
  String _selectedPharmacy = 'Any Pharmacy';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  Map<String, dynamic>? _deliveryAddress;
  String _paymentMethod = 'cash';
  bool _isUploading = false;
  final ImagePicker _imagePicker = ImagePicker();

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

  bool get _canSubmit =>
      _selectedFiles.isNotEmpty &&
      _selectedPharmacy.isNotEmpty &&
      _deliveryAddress != null &&
      _nameController.text.trim().isNotEmpty &&
      !_isUploading;

  // Track which sections are complete for visual feedback
  bool get _step1Done => _selectedFiles.isNotEmpty;
  bool get _step2Done => _selectedPharmacy.isNotEmpty;
  // ignore: unused_element
  bool get _step3Done => true; // Optional
  bool get _step4Done => _nameController.text.trim().isNotEmpty;
  bool get _step5Done => _deliveryAddress != null;
  bool get _step6Done => _paymentMethod.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Prescription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_selectedFiles.length} of $_maxImages added',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            _buildSourceTile(
              Icons.camera_alt_rounded,
              'Take Photo',
              'Capture prescription with camera',
              Colors.blue,
              isDark,
              () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            const SizedBox(height: 12),
            _buildSourceTile(
              Icons.photo_library_rounded,
              'Choose from Files',
              'Select image from your device',
              Colors.orange,
              isDark,
              () {
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

  Widget _buildSourceTile(
    IconData icon,
    String title,
    String sub,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.08) : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
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
    if (_selectedFiles.length >= _maxImages) {
      _showMaxLimitSnackbar();
      return;
    }
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(
          () => _selectedFiles.add(
            PickedImage(name: image.name, size: bytes.length, bytes: bytes),
          ),
        );
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _pickFromFiles() async {
    if (_selectedFiles.length >= _maxImages) {
      _showMaxLimitSnackbar();
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result != null) {
        for (var file in result.files.take(
          _maxImages - _selectedFiles.length,
        )) {
          if (file.bytes != null) {
            setState(
              () => _selectedFiles.add(
                PickedImage(
                  name: file.name,
                  size: file.size,
                  bytes: file.bytes!,
                ),
              ),
            );
          }
        }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _selectAddress() async {
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

  // ===== SUBMISSION =====

  void _submitOrder() async {
    setState(() => _isUploading = true);
    try {
      final userId = supabase.auth.currentUser!.id;

      final orderResponse = await supabase
          .from('orders')
          .insert({
            'user_id': userId,
            'order_name': _nameController.text.trim(),
            'pharmacy_name': _selectedPharmacy,
            'pharmacy_address': _selectedPharmacy == 'Any Pharmacy'
                ? 'Auto-assigned'
                : 'Specific selection',
            'status': 'order_placed',
            'notes': _notesController.text.trim(),
            'delivery_address_id': _deliveryAddress!['id'],
            'payment_method': _paymentMethod,
            'total_price': 0.00,
          })
          .select()
          .single();

      final orderId = orderResponse['id'];

      for (var file in _selectedFiles) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
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

      if (!mounted) return;
      _showSuccessDialog(orderId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSuccessDialog(String orderId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shortId = orderId.substring(0, 8).toUpperCase();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Animation
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.green.shade600,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order Placed! 🎉',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your prescription is being reviewed by the pharmacist.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // Order ID Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_rounded,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#ORD-$shortId',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== BUILD =====

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final cardColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF8F9FA);
    final inputBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_rounded, color: textColor, size: 20),
          ),
        ),
        title: Text(
          'New Order',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressBar(),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // 1. PRESCRIPTIONS
                  _buildSectionHeader(
                    '1',
                    'Upload Prescriptions',
                    _step1Done,
                    isDark,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload up to $_maxImages prescription images',
                    style: TextStyle(fontSize: 13, color: subtextColor),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedFiles.isNotEmpty) _buildImageGrid(isDark),
                  if (_selectedFiles.length < _maxImages)
                    _buildImagePickerButton(isDark, borderColor),

                  const SizedBox(height: 28),

                  // 2. PHARMACY
                  _buildSectionHeader(
                    '2',
                    'Choose Pharmacy',
                    _step2Done,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  ..._pharmacies.map(
                    (p) => _buildPharmacyCard(
                      p,
                      isDark,
                      cardColor,
                      textColor,
                      subtextColor,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 3. NOTES
                  _buildSectionHeader('3', 'Add Notes', true, isDark),
                  const SizedBox(height: 4),
                  Text(
                    'Optional',
                    style: TextStyle(fontSize: 13, color: subtextColor),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: TextStyle(fontSize: 15, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'e.g. "Only need the tablets, not the syrup"',
                        hintStyle: TextStyle(color: hintColor, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 4. ORDER NAME
                  _buildSectionHeader(
                    '4',
                    'Name this Order',
                    _step4Done,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(fontSize: 15, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'e.g. Mom\'s Medicine',
                        hintStyle: TextStyle(color: hintColor, fontSize: 14),
                        prefixIcon: Icon(
                          Icons.edit_rounded,
                          color: subtextColor,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _nameSuggestions.map((name) {
                      final isSelected = _nameController.text == name;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _nameController.text = name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                      ? Colors.teal.shade900
                                      : Colors.teal.shade50)
                                : (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.teal.shade600
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.teal.shade700
                                  : subtextColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // 5. ADDRESS
                  _buildSectionHeader(
                    '5',
                    'Delivery Address',
                    _step5Done,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _selectAddress,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _deliveryAddress != null
                              ? (isDark
                                    ? Colors.teal.shade700
                                    : Colors.teal.shade400)
                              : borderColor,
                          width: _deliveryAddress != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _deliveryAddress != null
                                  ? (isDark
                                        ? Colors.teal.shade900
                                        : Colors.teal.shade50)
                                  : (isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _deliveryAddress != null
                                  ? Icons.location_on_rounded
                                  : Icons.add_location_alt_rounded,
                              color: _deliveryAddress != null
                                  ? Colors.teal.shade600
                                  : Colors.grey,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _deliveryAddress != null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _deliveryAddress!['label'] ?? 'Address',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _deliveryAddress!['address_line'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: subtextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Select delivery address',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: subtextColor,
                                    ),
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
                  ),
                  // Change Address link
                  if (_deliveryAddress != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: _selectAddress,
                        child: Text(
                          'Change address',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal.shade600,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // 6. PAYMENT
                  _buildSectionHeader(
                    '6',
                    'Payment Method',
                    _step6Done,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    'Cash on Delivery',
                    'Pay when medicine arrives',
                    'cash',
                    Icons.payments_rounded,
                    true,
                    isDark,
                    cardColor,
                    textColor,
                    subtextColor,
                    borderColor,
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    'Card / Online',
                    'Coming soon',
                    'card',
                    Icons.credit_card_rounded,
                    false,
                    isDark,
                    cardColor,
                    textColor,
                    subtextColor,
                    borderColor,
                  ),

                  const SizedBox(height: 32),

                  // Security note
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: subtextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Your prescription is encrypted and secure',
                          style: TextStyle(fontSize: 12, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),

      // Floating Submit Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submitOrder : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                disabledBackgroundColor: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                foregroundColor: Colors.white,
                disabledForegroundColor: isDark
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== WIDGETS =====

  Widget _buildProgressBar() {
    int completed = 0;
    if (_step1Done) completed++;
    if (_step2Done) completed++;
    if (_step4Done) completed++;
    if (_step5Done) completed++;
    if (_step6Done) completed++;
    double progress = completed / 5;

    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation(
            progress == 1.0 ? Colors.green : Colors.teal.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String num,
    String title,
    bool isDone,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? (isDark ? Colors.green.shade900 : Colors.green.shade50)
                : (isDark ? Colors.teal.shade900 : Colors.teal.shade50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: isDone
                ? Icon(
                    Icons.check_rounded,
                    color: Colors.green.shade600,
                    size: 16,
                  )
                : Text(
                    num,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal.shade700,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _selectedFiles.asMap().entries.map((entry) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  entry.value.bytes,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              // File size badge
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(entry.value.size / 1024).toStringAsFixed(0)}KB',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Remove button
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _selectedFiles.removeAt(entry.key)),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImagePickerButton(bool isDark, Color borderColor) {
    return GestureDetector(
      onTap: _showImageSourceModal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              _selectedFiles.isEmpty
                  ? Icons.cloud_upload_outlined
                  : Icons.add_photo_alternate_outlined,
              size: 36,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 10),
            Text(
              _selectedFiles.isEmpty ? 'Upload prescription' : 'Add another',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Camera or Files',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyCard(
    Map<String, String> pharmacy,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    final isSelected = _selectedPharmacy == pharmacy['name'];
    final isAuto = pharmacy['type'] == 'auto';

    return GestureDetector(
      onTap: () => setState(() => _selectedPharmacy = pharmacy['name']!),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isAuto
                    ? (isDark
                          ? Colors.blue.shade900.withOpacity(0.2)
                          : Colors.blue.shade50)
                    : (isDark
                          ? Colors.teal.shade900.withOpacity(0.2)
                          : Colors.teal.shade50))
              : cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isAuto
                      ? (isDark ? Colors.blue.shade700 : Colors.blue.shade400)
                      : (isDark ? Colors.teal.shade700 : Colors.teal.shade400))
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isAuto
                          ? (isDark
                                ? Colors.blue.shade800
                                : Colors.blue.shade100)
                          : (isDark
                                ? Colors.teal.shade800
                                : Colors.teal.shade100))
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isAuto ? Icons.near_me_rounded : Icons.local_pharmacy_rounded,
                color: isSelected
                    ? (isAuto
                          ? (isDark
                                ? Colors.blue.shade300
                                : Colors.blue.shade700)
                          : (isDark
                                ? Colors.teal.shade300
                                : Colors.teal.shade700))
                    : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy['name']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pharmacy['address']!,
                    style: TextStyle(fontSize: 13, color: subtextColor),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: isAuto
                    ? (isDark ? Colors.blue.shade400 : Colors.blue.shade600)
                    : (isDark ? Colors.teal.shade400 : Colors.teal.shade600),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    String subtitle,
    String value,
    IconData icon,
    bool enabled,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    final isSelected = _paymentMethod == value && enabled;

    return GestureDetector(
      onTap: enabled
          ? () => setState(() => _paymentMethod = value)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text('Online payment coming soon!'),
                    ],
                  ),
                  backgroundColor: Colors.blue.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? Colors.teal.shade900.withOpacity(0.3)
                      : Colors.teal.shade50)
                : cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.teal.shade700 : Colors.teal.shade400)
                  : borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.teal.shade800 : Colors.teal.shade100)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.teal.shade600 : Colors.grey,
                  size: 22,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: subtextColor),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
                  size: 22,
                ),
              if (!enabled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Soon',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
