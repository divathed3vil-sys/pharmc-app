import 'package:flutter/material.dart';
import '../../services/address_service.dart';
import 'add_address_screen.dart';
import '../../services/verification_service.dart';
import 'local_saved_address_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  final bool selectMode;

  const SavedAddressesScreen({super.key, this.selectMode = false});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);

    final isApproved = await VerificationService.isApproved();

    if (!isApproved) {
      if (!mounted) return;
      setState(() {
        _addresses = [];
        _isLoading = false;
      });
      return;
    }

    final data = await AddressService.getAddresses();
    if (mounted) {
      setState(() {
        _addresses = data;
        _isLoading = false;
      });
    }
  }

  void _addNew() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAddressScreen()),
    );
    if (result == true) _loadAddresses();
  }

  void _edit(Map<String, dynamic> address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAddressScreen(existingAddress: address),
      ),
    );
    if (result == true) _loadAddresses();
  }

  void _delete(String id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final dialogText = isDark ? Colors.white : const Color(0xFF1A1A1A);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: dialogBg,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade500,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Address?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: dialogText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This address will be permanently removed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await AddressService.deleteAddress(id);
                          _loadAddresses();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade500,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setDefault(String id) async {
    await AddressService.setDefault(id);
    _loadAddresses();
  }

  void _selectAddress(Map<String, dynamic> address) {
    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final backBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA);

    return FutureBuilder<bool>(
      future: VerificationService.isApproved(),
      builder: (context, snap) {
        final approved = snap.data == true;

        // While checking, show a clean loader
        if (!snap.hasData) {
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
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: textColor,
                    size: 20,
                  ),
                ),
              ),
              title: Text(
                widget.selectMode ? 'Select Address' : 'Saved Addresses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: CircularProgressIndicator(color: Colors.teal.shade600),
            ),
          );
        }

        // If not approved: use local address UI
        if (!approved) {
          return LocalSavedAddressScreen(selectMode: widget.selectMode);
        }

        // If approved: show DB-based address UI
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
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: textColor,
                  size: 20,
                ),
              ),
            ),
            title: Text(
              widget.selectMode ? 'Select Address' : 'Saved Addresses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            centerTitle: true,
            actions: [
              GestureDetector(
                onTap: _addNew,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.teal.shade900.withOpacity(0.4)
                        : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: Colors.teal.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: Colors.teal.shade600),
                )
              : _addresses.isEmpty
              ? _buildEmptyState(isDark, subtextColor)
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildAddressCard(
                      _addresses[index],
                      isDark,
                      textColor,
                      subtextColor,
                      cardBg,
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildAddressCard(
    Map<String, dynamic> address,
    bool isDark,
    Color textColor,
    Color subtextColor,
    Color cardBg,
  ) {
    final isDefault = address['is_default'] == true;
    final hasGPS = address['latitude'] != null;
    final label = address['label'] ?? 'Home';

    IconData labelIcon;
    switch (label) {
      case 'Work':
        labelIcon = Icons.work_rounded;
        break;
      case 'Other':
        labelIcon = Icons.location_on_rounded;
        break;
      default:
        labelIcon = Icons.home_rounded;
    }

    return GestureDetector(
      onTap: widget.selectMode ? () => _selectAddress(address) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDefault
              ? (isDark
                    ? Colors.teal.shade900.withOpacity(0.2)
                    : Colors.teal.shade50.withOpacity(0.5))
              : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDefault
                ? (isDark ? Colors.teal.shade700 : Colors.teal.shade300)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            width: isDefault ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.teal.shade900 : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(labelIcon, color: Colors.teal.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 8),
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.teal.shade800
                          : Colors.teal.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                if (hasGPS) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.blue.shade900
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gps_fixed_rounded,
                          size: 10,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'GPS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                if (widget.selectMode)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: subtextColor,
                    size: 22,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Text(
                address['address_line'] ?? '',
                style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
              ),
            ),
            if (address['city'] != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Text(
                  address['city'],
                  style: TextStyle(fontSize: 13, color: subtextColor),
                ),
              ),
            ],
            if (!widget.selectMode) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Row(
                  children: [
                    if (!isDefault)
                      _buildActionChip(
                        label: 'Set Default',
                        icon: Icons.check_circle_outline_rounded,
                        color: Colors.teal,
                        isDark: isDark,
                        onTap: () => _setDefault(address['id']),
                      ),
                    if (!isDefault) const SizedBox(width: 8),
                    _buildActionChip(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      color: Colors.blue,
                      isDark: isDark,
                      onTap: () => _edit(address),
                    ),
                    const SizedBox(width: 8),
                    _buildActionChip(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      color: Colors.red,
                      isDark: isDark,
                      onTap: () => _delete(address['id']),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required MaterialColor color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? color.shade900.withOpacity(0.3) : color.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color subtextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 72,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No saved addresses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first delivery address',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _addNew,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Add Address',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
