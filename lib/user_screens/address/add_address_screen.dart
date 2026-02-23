import 'package:flutter/material.dart';
import '../../services/address_service.dart';

class AddAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAddress; // null = adding new

  const AddAddressScreen({super.key, this.existingAddress});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedLabel = 'Home';
  bool _isDefault = false;
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  double? _latitude;
  double? _longitude;
  String? _errorMessage;

  final List<Map<String, dynamic>> _labels = [
    {'label': 'Home', 'icon': Icons.home_rounded},
    {'label': 'Work', 'icon': Icons.work_rounded},
    {'label': 'Other', 'icon': Icons.location_on_rounded},
  ];

  bool get _isEditing => widget.existingAddress != null;

  bool get _canSave =>
      _addressController.text.trim().length >= 5 &&
      _cityController.text.trim().isNotEmpty &&
      !_isLoading;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final addr = widget.existingAddress!;
      _addressController.text = addr['address_line'] ?? '';
      _cityController.text = addr['city'] ?? '';
      _selectedLabel = addr['label'] ?? 'Home';
      _isDefault = addr['is_default'] ?? false;
      _latitude = addr['latitude'];
      _longitude = addr['longitude'];
    }
    _addressController.addListener(
      () => setState(() {
        _errorMessage = null;
      }),
    );
    _cityController.addListener(
      () => setState(() {
        _errorMessage = null;
      }),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _useCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _errorMessage = null;
    });

    // For now we simulate GPS — real GPS requires geolocator package
    // We'll add real GPS later
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isFetchingLocation = false;
      _latitude = 6.9271;
      _longitude = 79.8612;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'GPS location captured! (Demo coordinates — real GPS coming soon)',
        ),
        backgroundColor: Colors.teal.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _save() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    AddressResult result;

    if (_isEditing) {
      result = await AddressService.updateAddress(
        id: widget.existingAddress!['id'],
        label: _selectedLabel,
        addressLine: _addressController.text.trim(),
        city: _cityController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        isDefault: _isDefault,
      );
    } else {
      result = await AddressService.addAddress(
        label: _selectedLabel,
        addressLine: _addressController.text.trim(),
        city: _cityController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        isDefault: _isDefault,
      );
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      Navigator.pop(context, true); // true = refresh parent
    } else {
      setState(() {
        _errorMessage = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final inputBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final backBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA);

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
          _isEditing ? 'Edit Address' : 'Add Address',
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
            const SizedBox(height: 20),

            // GPS Button
            GestureDetector(
              onTap: _isFetchingLocation ? null : _useCurrentLocation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.teal.shade900.withOpacity(0.3)
                      : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.teal.shade700 : Colors.teal.shade200,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.teal.shade800
                            : Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isFetchingLocation
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                color: Colors.teal.shade600,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Icon(
                              _latitude != null
                                  ? Icons.check_circle_rounded
                                  : Icons.my_location_rounded,
                              color: Colors.teal.shade600,
                              size: 22,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _latitude != null
                                ? 'Location captured'
                                : 'Use current location',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.teal.shade300
                                  : Colors.teal.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _latitude != null
                                ? 'GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                                : 'Tap to detect your GPS coordinates',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.teal.shade400
                                  : Colors.teal.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_latitude != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _latitude = null;
                            _longitude = null;
                          });
                        },
                        child: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Label selection
            Text(
              'Address Label',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _labels.map((item) {
                final isSelected = _selectedLabel == item['label'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLabel = item['label'] as String;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        right: item != _labels.last ? 10 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                  ? Colors.teal.shade900.withOpacity(0.4)
                                  : Colors.teal.shade50)
                            : cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (isDark
                                    ? Colors.teal.shade700
                                    : Colors.teal.shade400)
                              : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 22,
                            color: isSelected
                                ? Colors.teal.shade600
                                : iconColor,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.teal.shade600
                                  : subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Address line
            Text(
              'Street Address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _addressController,
                textCapitalization: TextCapitalization.words,
                maxLines: 2,
                enabled: !_isLoading,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 45/2, Galle Road, Dehiwala',
                  hintStyle: TextStyle(
                    color: hintColor,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // City
            Text(
              'City',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _cityController,
                textCapitalization: TextCapitalization.words,
                enabled: !_isLoading,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Colombo',
                  hintStyle: TextStyle(
                    color: hintColor,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    Icons.apartment_rounded,
                    color: iconColor,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 17,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Default toggle
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDefault = !_isDefault;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isDefault
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: _isDefault ? Colors.teal.shade600 : iconColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set as default address',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'This will be pre-selected for new orders',
                            style: TextStyle(fontSize: 12, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.red.shade900.withOpacity(0.3)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.red.shade800 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.red.shade300
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _canSave ? _save : null,
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
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Address' : 'Save Address',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
