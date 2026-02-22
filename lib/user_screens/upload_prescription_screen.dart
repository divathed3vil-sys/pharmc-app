import 'package:flutter/material.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  final List<String> _uploadedImages = [];
  final int _maxImages = 3;
  String _selectedPharmacy = '';
  final TextEditingController _notesController = TextEditingController();

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
    {
      'name': 'MediCare Pharmacy',
      'address': '78 Kandy Road, Kaduwela',
      'distance': '4.1 km',
      'type': 'specific',
    },
  ];

  bool get _canSubmit =>
      _uploadedImages.isNotEmpty && _selectedPharmacy.isNotEmpty;

  void _pickImage(String source) {
    if (_uploadedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maximum 3 prescriptions allowed'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    setState(() {
      _uploadedImages.add(
        'Prescription ${_uploadedImages.length + 1} ($source)',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image ${_uploadedImages.length} added from $source'),
        backgroundColor: Colors.teal.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
    });
  }

  void _submitOrder() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dialogTextColor = isDark
        ? Colors.white
        : const Color(0xFF1A1A1A);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                  color: dialogTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedPharmacy == 'Any Pharmacy'
                    ? '${_uploadedImages.length} prescription(s) sent to\nthe nearest available pharmacy.'
                    : '${_uploadedImages.length} prescription(s) sent to\n$_selectedPharmacy for review.',
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
            // Step 1: Upload Images
            _buildSectionLabel('1', 'Upload Prescriptions', textColor, isDark),
            const SizedBox(height: 4),
            Text(
              'You can upload up to $_maxImages prescriptions',
              style: TextStyle(fontSize: 13, color: subtextColor),
            ),
            const SizedBox(height: 12),
            if (_uploadedImages.isNotEmpty) ...[
              ..._uploadedImages.asMap().entries.map(
                (entry) => _buildImageCard(entry.key, entry.value, isDark),
              ),
              const SizedBox(height: 8),
            ],
            if (_uploadedImages.length < _maxImages)
              _buildImagePicker(
                isDark,
                borderColor,
                uploadIconColor,
                uploadTextColor,
                subtextColor,
              ),
            if (_uploadedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_uploadedImages.length} of $_maxImages uploaded',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade600,
                  ),
                ),
              ),
            const SizedBox(height: 28),
            // Step 2: Select Pharmacy
            _buildSectionLabel('2', 'Choose Pharmacy', textColor, isDark),
            const SizedBox(height: 12),
            ..._pharmacies.map(
              (pharmacy) => _buildPharmacyCard(
                pharmacy,
                isDark,
                cardColor,
                textColor,
                subtextColor,
              ),
            ),
            const SizedBox(height: 28),
            // Step 3: Notes
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
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submitOrder : null,
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
                child: const Text(
                  'Submit Prescription',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
    return Container(
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
            _uploadedImages.isEmpty
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
            'JPG, PNG or PDF supported',
            style: TextStyle(fontSize: 13, color: subtextColor),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPickerButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => _pickImage('Camera'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPickerButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => _pickImage('Gallery'),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.teal.shade900 : Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.teal.shade700),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(int index, String imageName, bool isDark) {
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? Colors.teal.shade800 : Colors.teal.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.image_rounded,
              color: Colors.teal.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  imageName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.teal.shade300 : Colors.teal.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap × to remove',
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
      onTap: () {
        setState(() {
          _selectedPharmacy = pharmacy['name']!;
        });
      },
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
