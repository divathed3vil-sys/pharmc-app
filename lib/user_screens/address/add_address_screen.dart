import 'package:flutter/material.dart';
import '../../services/address_service.dart';

class AddAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAddress;

  const AddAddressScreen({super.key, this.existingAddress});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // GPS Mode state
  bool _isFetchingLocation = false;
  double? _gpsLatitude;
  double? _gpsLongitude;
  String? _gpsDetectedAddress;

  // Manual Mode state
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  // Common state
  String _selectedLabel = 'Home';
  bool _isDefault = false;
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _labels = [
    {'label': 'Home', 'icon': Icons.home_rounded},
    {'label': 'Work', 'icon': Icons.work_rounded},
    {'label': 'Other', 'icon': Icons.location_on_rounded},
  ];

  bool get _isEditing => widget.existingAddress != null;

  // Check if GPS mode is valid
  bool get _gpsIsValid => _gpsLatitude != null && _gpsDetectedAddress != null;

  // Check if Manual mode is valid
  bool get _manualIsValid =>
      _addressController.text.trim().length >= 5 &&
      _cityController.text.trim().isNotEmpty;

  // Check current tab and validate accordingly
  bool get _canSave {
    if (_isLoading) return false;
    if (_tabController.index == 0) {
      return _gpsIsValid;
    } else {
      return _manualIsValid;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));

    if (_isEditing) {
      final addr = widget.existingAddress!;
      _addressController.text = addr['address_line'] ?? '';
      _cityController.text = addr['city'] ?? '';
      _selectedLabel = addr['label'] ?? 'Home';
      _isDefault = addr['is_default'] ?? false;

      // If editing and has GPS, show in GPS tab
      if (addr['latitude'] != null) {
        _gpsLatitude = addr['latitude'];
        _gpsLongitude = addr['longitude'];
        _gpsDetectedAddress = addr['address_line'];
      } else {
        // Default to manual tab if editing manual address
        _tabController.index = 1;
      }
    }

    _addressController.addListener(() => setState(() => _errorMessage = null));
    _cityController.addListener(() => setState(() => _errorMessage = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _fetchGPSLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _errorMessage = null;
    });

    // Simulate GPS fetch (replace with real geolocator later)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Demo coordinates (Colombo, Sri Lanka)
    setState(() {
      _isFetchingLocation = false;
      _gpsLatitude = 6.9271;
      _gpsLongitude = 79.8612;
      _gpsDetectedAddress = '45 Galle Road, Colombo 03';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Location detected successfully!'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _clearGPS() {
    setState(() {
      _gpsLatitude = null;
      _gpsLongitude = null;
      _gpsDetectedAddress = null;
    });
  }

  void _save() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isGPSMode = _tabController.index == 0;

    AddressResult result;

    if (_isEditing) {
      result = await AddressService.updateAddress(
        id: widget.existingAddress!['id'],
        label: _selectedLabel,
        addressLine: isGPSMode
            ? _gpsDetectedAddress!
            : _addressController.text.trim(),
        city: isGPSMode ? 'GPS Location' : _cityController.text.trim(),
        latitude: isGPSMode ? _gpsLatitude : null,
        longitude: isGPSMode ? _gpsLongitude : null,
        isDefault: _isDefault,
      );
    } else {
      result = await AddressService.addAddress(
        label: _selectedLabel,
        addressLine: isGPSMode
            ? _gpsDetectedAddress!
            : _addressController.text.trim(),
        city: isGPSMode ? 'GPS Location' : _cityController.text.trim(),
        latitude: isGPSMode ? _gpsLatitude : null,
        longitude: isGPSMode ? _gpsLongitude : null,
        isDefault: _isDefault,
      );
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final backBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
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
      body: Column(
        children: [
          // Tab Selector
          Container(
            margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.teal.shade600,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: subtextColor,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gps_fixed_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Use GPS'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Enter Manually'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGPSTab(isDark, textColor, subtextColor, cardBg),
                _buildManualTab(isDark, textColor, subtextColor, cardBg),
              ],
            ),
          ),

          // Bottom Section (Label + Default + Save)
          _buildBottomSection(isDark, textColor, subtextColor, cardBg),
        ],
      ),
    );
  }

  Widget _buildGPSTab(
    bool isDark,
    Color textColor,
    Color subtextColor,
    Color cardBg,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // GPS Illustration
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.teal.shade900.withOpacity(0.3)
                  : Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _gpsIsValid
                  ? Icons.check_circle_rounded
                  : Icons.location_searching_rounded,
              size: 50,
              color: _gpsIsValid ? Colors.green.shade600 : Colors.teal.shade600,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            _gpsIsValid ? 'Location Detected!' : 'Detect Your Location',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _gpsIsValid
                ? 'We found your address using GPS'
                : 'Use GPS to automatically find your address',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: subtextColor),
          ),

          const SizedBox(height: 24),

          // Detected Address Card
          if (_gpsIsValid)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.green.shade900.withOpacity(0.2)
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.green.shade700 : Colors.green.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Detected Address',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _gpsDetectedAddress!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Coordinates: ${_gpsLatitude!.toStringAsFixed(4)}, ${_gpsLongitude!.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Locate Me Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isFetchingLocation
                  ? null
                  : (_gpsIsValid ? _clearGPS : _fetchGPSLocation),
              icon: _isFetchingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _gpsIsValid
                          ? Icons.refresh_rounded
                          : Icons.my_location_rounded,
                    ),
              label: Text(
                _isFetchingLocation
                    ? 'Detecting...'
                    : (_gpsIsValid ? 'Detect Again' : 'Locate Me'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gpsIsValid
                    ? Colors.grey.shade600
                    : Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTab(
    bool isDark,
    Color textColor,
    Color subtextColor,
    Color cardBg,
  ) {
    final inputBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Street Address
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

          const SizedBox(height: 20),

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

          // Validation hint
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _manualIsValid
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: _manualIsValid ? Colors.green : subtextColor,
              ),
              const SizedBox(width: 6),
              Text(
                _manualIsValid
                    ? 'Address is complete'
                    : 'Enter at least 5 characters for address',
                style: TextStyle(
                  fontSize: 12,
                  color: _manualIsValid ? Colors.green : subtextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
    bool isDark,
    Color textColor,
    Color subtextColor,
    Color cardBg,
  ) {
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label Selection
          Row(
            children: _labels.map((item) {
              final isSelected = _selectedLabel == item['label'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLabel = item['label']),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: item != _labels.last ? 10 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                                ? Colors.teal.shade900.withOpacity(0.4)
                                : Colors.teal.shade50)
                          : cardBg,
                      borderRadius: BorderRadius.circular(10),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 18,
                          color: isSelected ? Colors.teal.shade600 : iconColor,
                        ),
                        const SizedBox(width: 6),
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

          const SizedBox(height: 16),

          // Default toggle
          GestureDetector(
            onTap: () => setState(() => _isDefault = !_isDefault),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isDefault
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: _isDefault ? Colors.teal.shade600 : iconColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Set as default address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.red.shade900.withOpacity(0.3)
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Save Button
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
        ],
      ),
    );
  }
}
