import 'package:flutter/material.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  // Track up to 3 uploaded images (simulated for now)
  final List<String> _uploadedImages = [];
  final int _maxImages = 3;

  String _selectedPharmacy = '';
  final TextEditingController _notesController = TextEditingController();

  // Pharmacy list with "Any Pharmacy" as first option
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
      // Simulating image selection with a fake name
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              const Text(
                'Order Submitted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF1A1A1A),
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Upload Prescription',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
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
            _buildSectionLabel('1', 'Upload Prescriptions'),
            const SizedBox(height: 4),
            Text(
              'You can upload up to $_maxImages prescriptions',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),

            // Show uploaded images list
            if (_uploadedImages.isNotEmpty) ...[
              ..._uploadedImages.asMap().entries.map(
                (entry) => _buildImageCard(entry.key, entry.value),
              ),
              const SizedBox(height: 8),
            ],

            // Show upload picker if under limit
            if (_uploadedImages.length < _maxImages) _buildImagePicker(),

            // Image counter
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
            _buildSectionLabel('2', 'Choose Pharmacy'),
            const SizedBox(height: 12),

            ..._pharmacies.map((pharmacy) => _buildPharmacyCard(pharmacy)),

            const SizedBox(height: 28),

            // Step 3: Notes
            _buildSectionLabel('3', 'Add Notes (Optional)'),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText:
                      'E.g., "I only need the paracetamol, not the antibiotic"',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
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
                  disabledBackgroundColor: Colors.teal.shade100,
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
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Your prescription is encrypted and secure',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
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

  // Section label with step number
  Widget _buildSectionLabel(String step, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  // Upload picker (Camera + Gallery buttons)
  Widget _buildImagePicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            _uploadedImages.isEmpty
                ? 'Upload your prescription'
                : 'Add another prescription',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'JPG, PNG or PDF supported',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPickerButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => _pickImage('Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPickerButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => _pickImage('Gallery'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Camera / Gallery button
  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
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

  // Individual uploaded image card
  Widget _buildImageCard(int index, String imageName) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          // Thumbnail placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.image_rounded,
              color: Colors.teal.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Image info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  imageName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap × to remove',
                  style: TextStyle(fontSize: 12, color: Colors.teal.shade500),
                ),
              ],
            ),
          ),

          // Remove button
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

  // Pharmacy selection card
  Widget _buildPharmacyCard(Map<String, String> pharmacy) {
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
              ? (isAuto ? Colors.blue.shade50 : Colors.teal.shade50)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isAuto ? Colors.blue.shade400 : Colors.teal.shade400)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isAuto ? Colors.blue.shade100 : Colors.teal.shade100)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isAuto ? Icons.near_me_rounded : Icons.local_pharmacy_rounded,
                color: isSelected
                    ? (isAuto ? Colors.blue.shade700 : Colors.teal.shade700)
                    : Colors.grey.shade500,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Info
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
                                ? Colors.blue.shade800
                                : Colors.teal.shade800)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pharmacy['address']!,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // Distance badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isAuto ? Colors.blue.shade100 : Colors.teal.shade100)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                pharmacy['distance']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (isAuto ? Colors.blue.shade700 : Colors.teal.shade700)
                      : Colors.grey.shade600,
                ),
              ),
            ),

            // Checkmark
            if (isSelected) ...[
              const SizedBox(width: 10),
              Icon(
                Icons.check_circle_rounded,
                color: isAuto ? Colors.blue.shade600 : Colors.teal.shade600,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
