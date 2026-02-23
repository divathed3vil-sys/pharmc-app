import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../main.dart';
import 'address/saved_addresses_screen.dart';

// A simple class to hold picked file info across Web & Mobile
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
  bool _isUploading = false;
  final ImagePicker _imagePicker = ImagePicker();

  final List<Map<String, String>> _pharmacies = [
    {
      'name': 'Any Pharmacy',
      'address': 'We\'ll send to the nearest available pharmacy',
      'distance': 'Auto',
      'type': 'auto',
    },
    {
      'name': 'City Pharmacy',
      'address': '123 Main Street, Colombo 03',
      'distance': '1.2 km',
      'type': 'specific',
    },
    {
      'name': 'HealthPlus Pharmacy',
      'address': '45 Galle Road, Dehiwala',
      'distance': '2.8 km',
      'type': 'specific',
    },
  ];

  bool get _canSubmit =>
      _selectedFiles.isNotEmpty &&
      _selectedPharmacy.isNotEmpty &&
      !_isUploading;

  // ===== IMAGE PICKING LOGIC =====

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
              'Upload Prescription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how to add your prescription',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),

            // Camera Option
            _buildSourceTile(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              subtitle: 'Use camera to capture prescription',
              color: Colors.blue,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),

            const SizedBox(height: 12),

            // Files Option
            _buildSourceTile(
              icon: Icons.folder_rounded,
              title: 'Choose from Files',
              subtitle: 'Select image from your device',
              color: Colors.orange,
              isDark: isDark,
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

  Widget _buildSourceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.1) : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
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
    if (_selectedFiles.length >= _maxImages) return;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedFiles.add(
            PickedImage(name: image.name, size: bytes.length, bytes: bytes),
          );
        });
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _pickFromFiles() async {
    if (_selectedFiles.length >= _maxImages) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result != null) {
        int available = _maxImages - _selectedFiles.length;
        for (var file in result.files.take(available)) {
          if (file.bytes != null) {
            setState(() {
              _selectedFiles.add(
                PickedImage(
                  name: file.name,
                  size: file.size,
                  bytes: file.bytes!,
                ),
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  // ===== SUBMISSION LOGIC =====

  void _initiateSubmit() async {
    final selectedAddress = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SavedAddressesScreen(selectMode: true),
      ),
    );

    if (selectedAddress == null) return;
    _processUpload(selectedAddress['id']);
  }

  void _processUpload(String addressId) async {
    setState(() => _isUploading = true);

    try {
      final userId = supabase.auth.currentUser!.id;

      // 1. Create Order
      final orderResponse = await supabase
          .from('orders')
          .insert({
            'user_id': userId,
            'pharmacy_name': _selectedPharmacy,
            'pharmacy_address': _selectedPharmacy == 'Any Pharmacy'
                ? 'Auto-assigned'
                : 'Specific selection',
            'status': 'pending_review',
            'notes': _notesController.text.trim(),
            'delivery_address_id': addressId,
            'total_price': 0.00,
          })
          .select()
          .single();

      final orderId = orderResponse['id'];

      // 2. Upload each image
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

      // 3. Status history
      await supabase.from('order_status_history').insert({
        'order_id': orderId,
        'status': 'pending_review',
        'changed_by': userId,
        'note': 'Order created',
      });

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSuccessDialog() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color dialogText = isDark ? Colors.white : const Color(0xFF1A1A1A);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: dialogBg,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.green.shade600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Order Submitted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: dialogText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We have received your prescription. You will be notified when the price is ready.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
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
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ===== BUILD UI =====

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color subtextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade500;
    final Color cardColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF8F9FA);
    final Color inputBg = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF5F5F5);
    final Color backBg = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF5F5F5);
    final Color hintColor = isDark
        ? Colors.grey.shade600
        : Colors.grey.shade400;
    final Color borderColor = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
    final Color uploadIconColor = isDark
        ? Colors.grey.shade500
        : Colors.grey.shade400;
    final Color uploadTextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_rounded, color: textColor, size: 20),
          ),
        ),
        title: Text(
          'Upload Prescription',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Step 1
            _buildSectionLabel('1', 'Upload Prescriptions', textColor, isDark),
            const SizedBox(height: 4),
            Text(
              'You can upload up to $_maxImages prescriptions',
              style: TextStyle(fontSize: 13, color: subtextColor),
            ),
            const SizedBox(height: 12),

            if (_selectedFiles.isNotEmpty) ...[
              ..._selectedFiles.asMap().entries.map(
                (e) => _buildImageCard(e.key, e.value, isDark),
              ),
              const SizedBox(height: 8),
            ],

            if (_selectedFiles.length < _maxImages)
              _buildImagePicker(
                isDark,
                borderColor,
                uploadIconColor,
                uploadTextColor,
                subtextColor,
              ),

            if (_selectedFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_selectedFiles.length} of $_maxImages uploaded',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade600,
                  ),
                ),
              ),

            const SizedBox(height: 28),

            // Step 2
            _buildSectionLabel('2', 'Choose Pharmacy', textColor, isDark),
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

            // Step 3
            _buildSectionLabel('3', 'Add Notes (Optional)', textColor, isDark),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(fontSize: 15, color: textColor),
                decoration: InputDecoration(
                  hintText:
                      'E.g., "I only need the paracetamol, not the antibiotic"',
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canSubmit ? _initiateSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  disabledBackgroundColor: isDark
                      ? Colors.teal.shade900
                      : Colors.teal.shade100,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white60,
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
                    : const Text(
                        'Next: Choose Address',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ===== HELPER WIDGETS =====

  Widget _buildSectionLabel(
    String step,
    String title,
    Color textColor,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDark ? Colors.teal.shade900 : Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              step,
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
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(
    bool isDark,
    Color borderColor,
    Color iconColor,
    Color textColor,
    Color subtextColor,
  ) {
    return GestureDetector(
      onTap: _showImageSourceModal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined, size: 48, color: iconColor),
            const SizedBox(height: 12),
            Text(
              _selectedFiles.isEmpty
                  ? 'Upload your prescription'
                  : 'Add another prescription',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to choose Camera, Gallery, or Files',
              style: TextStyle(fontSize: 13, color: subtextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(int index, PickedImage file, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.teal.shade900.withOpacity(0.3)
            : Colors.teal.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.teal.shade700 : Colors.teal.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Show thumbnail preview
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              file.bytes,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.teal.shade300 : Colors.teal.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(file.size / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.teal.shade400 : Colors.teal.shade500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.red.shade400,
                size: 18,
              ),
            ),
          ),
        ],
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
                          ? Colors.blue.shade900.withOpacity(0.3)
                          : Colors.blue.shade50)
                    : (isDark
                          ? Colors.teal.shade900.withOpacity(0.3)
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
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
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
                      color: isSelected
                          ? (isAuto
                                ? (isDark
                                      ? Colors.blue.shade300
                                      : Colors.blue.shade800)
                                : (isDark
                                      ? Colors.teal.shade300
                                      : Colors.teal.shade800))
                          : textColor,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                pharmacy['distance']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (isAuto
                            ? (isDark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade700)
                            : (isDark
                                  ? Colors.teal.shade300
                                  : Colors.teal.shade700))
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              Icon(
                Icons.check_circle_rounded,
                color: isAuto
                    ? (isDark ? Colors.blue.shade400 : Colors.blue.shade600)
                    : (isDark ? Colors.teal.shade400 : Colors.teal.shade600),
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
