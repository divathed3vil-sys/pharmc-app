import 'dart:ui';
import 'package:flutter/material.dart';
import '../main.dart';

class OrderTrackingPopup extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderTrackingPopup({super.key, required this.order});

  static void show(BuildContext context, Map<String, dynamic> order) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) => OrderTrackingPopup(order: order),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }

  @override
  State<OrderTrackingPopup> createState() => _OrderTrackingPopupState();
}

class _OrderTrackingPopupState extends State<OrderTrackingPopup> {
  // 0 = tracking view, 1 = prescription view
  int _currentView = 0;
  List<Map<String, dynamic>> _prescriptionImages = [];
  bool _loadingImages = false;

  // Page controller for prescription swipe
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _loadingImages = true);
    try {
      final data = await supabase
          .from('prescription_images')
          .select()
          .eq('order_id', widget.order['id']);
      setState(() {
        _prescriptionImages = List<Map<String, dynamic>>.from(data);
        _loadingImages = false;
      });
    } catch (e) {
      debugPrint('Error loading prescriptions: $e');
      setState(() => _loadingImages = false);
    }
  }

  // Get tracking steps based on order status
  List<Map<String, dynamic>> _getTrackingSteps() {
    final status = widget.order['status'] ?? 'order_placed';

    final allSteps = [
      {'label': 'Order Placed', 'key': 'order_placed'},
      {'label': 'Pharmacist Verified', 'key': 'pharmacist_verified'},
      {'label': 'Price Confirmed', 'key': 'price_confirmed'},
      {'label': 'Preparing', 'key': 'preparing'},
      {'label': 'Out for Delivery', 'key': 'out_for_delivery'},
      {'label': 'Delivered', 'key': 'delivered'},
    ];

    final statusOrder = allSteps.map((s) => s['key']).toList();
    final currentIndex = statusOrder.indexOf(status);

    return allSteps.asMap().entries.map((entry) {
      return {
        'label': entry.value['label'],
        'key': entry.value['key'],
        'done': entry.key <= currentIndex,
        'isCurrent': entry.key == currentIndex,
      };
    }).toList();
  }

  // Get verification code display
  String? _getVerificationCode() {
    final status = widget.order['status'] ?? '';
    if (status == 'out_for_delivery') {
      return widget.order['verification_code'] ?? '----';
    }
    return null;
  }

  void _switchToPrescriptions() {
    setState(() => _currentView = 1);
  }

  void _switchToTracking() {
    setState(() => _currentView = 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.pop(context), // Tap background to close
      child: Stack(
        children: [
          // Blurred Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.black.withOpacity(isDark ? 0.6 : 0.4),
            ),
          ),

          // Popup Content
          Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping popup
              onVerticalDragEnd: (details) {
                // Swipe down to close
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 300) {
                  Navigator.pop(context);
                }
              },
              onHorizontalDragEnd: (details) {
                // Swipe left to show prescriptions
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -300) {
                  _switchToPrescriptions();
                }
                // Swipe right to go back to tracking
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 300) {
                  _switchToTracking();
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    final isForward = _currentView == 1;
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: Offset(isForward ? 1 : -1, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ),
                          ),
                      child: child,
                    );
                  },
                  child: _currentView == 0
                      ? _buildTrackingView(isDark)
                      : _buildPrescriptionView(isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== TRACKING VIEW =====
  Widget _buildTrackingView(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final cardBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA);
    final steps = _getTrackingSteps();
    final verificationCode = _getVerificationCode();
    final status = widget.order['status'] ?? 'order_placed';
    final statusConfig = _getStatusConfig(status);

    final orderName = widget.order['order_name'] ?? 'My Order';
    final orderId =
        widget.order['id']?.toString().substring(0, 8).toUpperCase() ?? '';
    final pharmacyName = widget.order['pharmacy_name'] ?? 'Pharmacy';
    final totalPrice = widget.order['total_price'] ?? 0.0;
    final paymentMethod = widget.order['payment_method'] ?? 'cash';

    return SingleChildScrollView(
      key: const ValueKey('tracking'),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Drag handle + Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Drag indicator
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Order Name + ID
            Text(
              orderName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '#ORD-$orderId',
                  style: TextStyle(
                    fontSize: 13,
                    color: subtextColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (statusConfig['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusConfig['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusConfig['color'] as Color,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Pharmacy Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_pharmacy_rounded,
                    size: 20,
                    color: Colors.teal.shade600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pharmacyName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  Icon(Icons.payments_rounded, size: 16, color: subtextColor),
                  const SizedBox(width: 4),
                  Text(
                    paymentMethod == 'cash' ? 'COD' : 'Card',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tracking Timeline
            Text(
              'Order Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: subtextColor,
              ),
            ),
            const SizedBox(height: 12),

            ...steps.asMap().entries.map((entry) {
              final step = entry.value;
              final isDone = step['done'] as bool;
              final isCurrent = step['isCurrent'] as bool;
              final isLast = entry.key == steps.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isDone
                              ? (isCurrent
                                    ? Colors.teal.shade600
                                    : Colors.teal.shade100)
                              : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200),
                          shape: BoxShape.circle,
                          border: isCurrent
                              ? Border.all(
                                  color: Colors.teal.shade300,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: isDone
                            ? Icon(
                                isCurrent
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.check_rounded,
                                size: 14,
                                color: isCurrent
                                    ? Colors.white
                                    : Colors.teal.shade700,
                              )
                            : null,
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 28,
                          color: isDone
                              ? Colors.teal.shade200
                              : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isDone
                            ? (isCurrent ? Colors.teal.shade700 : textColor)
                            : (isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400),
                      ),
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 20),

            // Verification Code Section
            _buildVerificationSection(
              verificationCode,
              isDark,
              textColor,
              subtextColor,
              cardBg,
            ),

            const SizedBox(height: 20),

            // Price Breakdown
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (totalPrice > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Medicine',
                          style: TextStyle(fontSize: 13, color: subtextColor),
                        ),
                        Text(
                          'LKR ${(widget.order['medicine_cost'] ?? 0.0).toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 13, color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery',
                          style: TextStyle(fontSize: 13, color: subtextColor),
                        ),
                        Text(
                          'LKR ${(widget.order['delivery_fee'] ?? 0.0).toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 13, color: textColor),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                        height: 1,
                      ),
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        totalPrice > 0
                            ? 'LKR ${totalPrice.toStringAsFixed(2)}'
                            : 'Pending',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: totalPrice > 0
                              ? Colors.teal.shade600
                              : Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Reject button (only when price is ready)
            if (status == 'price_confirmed') ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement reject logic
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Reject Price',
                    style: TextStyle(
                      color: Colors.red.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _switchToPrescriptions,
                      icon: const Icon(Icons.image_rounded, size: 18),
                      label: const Text(
                        'Prescriptions',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal.shade600,
                        side: BorderSide(color: Colors.teal.shade600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigate to Payment Screen (Part 3)
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text(
                        'Payment',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Swipe hint
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Swipe left to view prescriptions',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection(
    String? code,
    bool isDark,
    Color textColor,
    Color subtextColor,
    Color cardBg,
  ) {
    final status = widget.order['status'] ?? '';

    // Only show when relevant
    if (status != 'out_for_delivery' && status != 'delivered') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.pin_rounded, size: 20, color: subtextColor),
            const SizedBox(width: 10),
            Text(
              'Delivery Code',
              style: TextStyle(fontSize: 14, color: subtextColor),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Pending',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show PIN when out for delivery
    if (status == 'out_for_delivery') {
      final digits = (code ?? '----').split('');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.teal.shade900.withOpacity(0.3)
              : Colors.teal.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.teal.shade700 : Colors.teal.shade300,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: Colors.teal.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Show this code to delivery person',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: digits.map((d) {
                return Container(
                  width: 52,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.teal.shade400, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.shade200.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.teal.shade700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    // Delivered - Verified
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.green.shade900.withOpacity(0.2)
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Verified & Delivered',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ===== PRESCRIPTION VIEW =====
  Widget _buildPrescriptionView(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final notes = widget.order['notes'] ?? '';

    return Padding(
      key: const ValueKey('prescriptions'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Row(
            children: [
              GestureDetector(
                onTap: _switchToTracking,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Prescriptions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Images
          if (_loadingImages)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_prescriptionImages.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_not_supported_rounded,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No prescriptions found',
                      style: TextStyle(color: subtextColor),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _prescriptionImages.length,
                itemBuilder: (context, index) {
                  final image = _prescriptionImages[index];
                  final imagePath = image['image_url'] as String;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Image with zoom
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Center(
                              child: FutureBuilder<String>(
                                future: _getSignedUrl(imagePath),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const CircularProgressIndicator();
                                  }
                                  return Image.network(
                                    snapshot.data!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.broken_image_rounded,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        // Image counter badge
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${index + 1} / ${_prescriptionImages.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // Zoom hint
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.zoom_in_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Pinch to zoom',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Page dots
          if (_prescriptionImages.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_prescriptionImages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal.shade600.withOpacity(0.3),
                  ),
                );
              }),
            ),
          ],

          // Notes
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: subtextColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notes,
                style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
              ),
            ),
          ],

          const SizedBox(height: 16),
          Center(
            child: Text(
              'Swipe right to go back',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getSignedUrl(String path) async {
    final response = await supabase.storage
        .from('prescriptions')
        .createSignedUrl(path, 3600);
    return response;
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'order_placed':
        return {
          'label': 'Order Placed',
          'color': Colors.blue,
          'icon': Icons.receipt_rounded,
        };
      case 'pharmacist_verified':
        return {
          'label': 'Verified',
          'color': Colors.purple,
          'icon': Icons.verified_rounded,
        };
      case 'price_confirmed':
        return {
          'label': 'Price Ready',
          'color': Colors.orange,
          'icon': Icons.attach_money_rounded,
        };
      case 'preparing':
        return {
          'label': 'Preparing',
          'color': Colors.orange,
          'icon': Icons.access_time_rounded,
        };
      case 'out_for_delivery':
        return {
          'label': 'Out for Delivery',
          'color': Colors.blue,
          'icon': Icons.delivery_dining_rounded,
        };
      case 'delivered':
        return {
          'label': 'Delivered',
          'color': Colors.green,
          'icon': Icons.check_circle_rounded,
        };
      case 'cancelled':
        return {
          'label': 'Cancelled',
          'color': Colors.red,
          'icon': Icons.cancel_rounded,
        };
      default:
        return {
          'label': 'Pending',
          'color': Colors.grey,
          'icon': Icons.pending_rounded,
        };
    }
  }
}
