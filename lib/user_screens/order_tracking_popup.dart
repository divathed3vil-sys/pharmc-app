import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

// ============================================================
// ORDER TRACKING POPUP
// Glassmorphic bottom-sheet style with frosted glass
// Fixed zoom/pan: 2-finger zoom, disabled page swipe when zoomed
// ============================================================
class OrderTrackingPopup extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderTrackingPopup({super.key, required this.order});

  static void show(BuildContext context, Map<String, dynamic> order) {
    HapticFeedback.mediumImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => OrderTrackingPopup(order: order),
      transitionBuilder: (context, anim1, anim2, child) {
        final slideAnim = Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic));
        final fadeAnim = CurvedAnimation(parent: anim1, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fadeAnim,
          child: SlideTransition(position: slideAnim, child: child),
        );
      },
    );
  }

  @override
  State<OrderTrackingPopup> createState() => _OrderTrackingPopupState();
}

class _OrderTrackingPopupState extends State<OrderTrackingPopup>
    with SingleTickerProviderStateMixin {
  // ── View switching (tracking ↔ prescriptions) ──
  final PageController _viewController = PageController();
  int _currentView = 0;

  // ── Prescription state ──
  final PageController _imagePageController = PageController();
  int _currentImagePage = 0;
  List<Map<String, dynamic>> _prescriptionImages = [];
  bool _loadingImages = false;

  // ── Zoom controllers ──
  final Map<int, TransformationController> _zoomControllers = {};
  final Map<int, bool> _isZoomed = {};

  // ── Entrance animation ──
  late AnimationController _contentAnim;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();

    _contentAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFade = CurvedAnimation(
      parent: _contentAnim,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _contentAnim.forward();
    });
  }

  @override
  void dispose() {
    _viewController.dispose();
    _imagePageController.dispose();
    _contentAnim.dispose();
    for (final c in _zoomControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TransformationController _zoomFor(int index) {
    return _zoomControllers.putIfAbsent(index, () {
      final ctrl = TransformationController();
      ctrl.addListener(() {
        final zoomed = ctrl.value.getMaxScaleOnAxis() > 1.05;
        if (_isZoomed[index] != zoomed) {
          setState(() => _isZoomed[index] = zoomed);
        }
      });
      return ctrl;
    });
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

  Future<String> _getSignedUrl(String path) async {
    return supabase.storage.from('prescriptions').createSignedUrl(path, 3600);
  }

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

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'order_placed':
        return {
          'label': 'Placed',
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
          'color': Colors.amber,
          'icon': Icons.access_time_rounded,
        };
      case 'out_for_delivery':
        return {
          'label': 'On the way',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // ── Frosted background ──
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: Colors.black.withOpacity(isDark ? 0.65 : 0.4),
              ),
            ),
          ),

          // ── Popup card ──
          Center(
            child: GestureDetector(
              onTap: () {}, // Prevent tap-through
              child: Container(
                width: screenWidth * 0.92,
                height: screenHeight * 0.82,
                decoration: BoxDecoration(
                  // ── Frosted glass card ──
                  color: isDark
                      ? const Color(0xFF1A1A1A).withOpacity(0.92)
                      : Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: Column(
                      children: [
                        // ── Drag handle ──
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // ── View switcher tabs ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: _buildViewSwitcher(isDark),
                        ),

                        const SizedBox(height: 4),

                        // ── Content ──
                        Expanded(
                          child: PageView(
                            controller: _viewController,
                            onPageChanged: (i) =>
                                setState(() => _currentView = i),
                            physics: const ClampingScrollPhysics(),
                            children: [
                              _buildTrackingView(isDark),
                              _buildPrescriptionView(isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // VIEW SWITCHER (Frosted pill tabs)
  // ════════════════════════════════════════
  Widget _buildViewSwitcher(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _buildSwitcherTab(
                0,
                'Tracking',
                Icons.location_on_outlined,
                isDark,
              ),
              _buildSwitcherTab(
                1,
                'Prescriptions',
                Icons.image_outlined,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitcherTab(
    int index,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _currentView == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _viewController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? Colors.teal.shade700.withOpacity(0.3)
                      : Colors.teal.shade500)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // TRACKING VIEW
  // ════════════════════════════════════════
  Widget _buildTrackingView(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final innerBg = isDark ? const Color(0xFF222222) : const Color(0xFFF5F6F8);
    final steps = _getTrackingSteps();
    final status = widget.order['status'] ?? 'order_placed';
    final config = _getStatusConfig(status);
    final orderName = widget.order['order_name'] ?? 'My Order';
    final orderId =
        widget.order['id']?.toString().substring(0, 8).toUpperCase() ?? '';
    final pharmacyName = widget.order['pharmacy_name'] ?? 'Pharmacy';
    final totalPrice = (widget.order['total_price'] as num?)?.toDouble() ?? 0.0;
    final medicineCost =
        (widget.order['medicine_cost'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee =
        (widget.order['delivery_fee'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = widget.order['payment_method'] ?? 'cash';
    final verificationCode =
        widget.order['verification_code']?.toString() ?? '----';
    final showCode = status == 'out_for_delivery';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Order header ──
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (config['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  config['icon'] as IconData,
                  color: config['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '#$orderId',
                          style: TextStyle(fontSize: 12, color: subtextColor),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (config['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            config['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: config['color'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Close ──
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
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

          const SizedBox(height: 18),

          // ── Pharmacy + Payment ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: innerBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_pharmacy_rounded,
                  size: 18,
                  color: Colors.teal.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pharmacyName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                Icon(Icons.payments_rounded, size: 14, color: subtextColor),
                const SizedBox(width: 4),
                Text(
                  paymentMethod == 'cash' ? 'COD' : 'Card',
                  style: TextStyle(fontSize: 11, color: subtextColor),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Tracking steps ──
          Text(
            'ORDER PROGRESS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: subtextColor,
              letterSpacing: 1,
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
                      width: 24,
                      height: 24,
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
                            ? Border.all(color: Colors.teal.shade300, width: 2)
                            : null,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: Colors.teal.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: -2,
                                ),
                              ]
                            : [],
                      ),
                      child: isDone
                          ? Icon(
                              isCurrent
                                  ? Icons.radio_button_checked
                                  : Icons.check_rounded,
                              size: 13,
                              color: isCurrent
                                  ? Colors.white
                                  : Colors.teal.shade700,
                            )
                          : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 24,
                        color: isDone
                            ? Colors.teal.shade200
                            : (isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    step['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                      color: isDone
                          ? (isCurrent ? Colors.teal.shade600 : textColor)
                          : (isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade400),
                    ),
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 18),

          // ── Verification code ──
          if (showCode)
            _buildCodeBox(verificationCode, isDark)
          else if (status == 'delivered')
            _buildDeliveredBadge(isDark)
          else
            _buildPendingCodeBadge(isDark, subtextColor),

          const SizedBox(height: 16),

          // ── Price summary ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: innerBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (totalPrice > 0) ...[
                  _priceRow('Medicine', medicineCost, textColor, subtextColor),
                  const SizedBox(height: 6),
                  _priceRow('Delivery', deliveryFee, textColor, subtextColor),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      color: isDark
                          ? Colors.grey.shade800
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
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      totalPrice > 0
                          ? 'LKR ${totalPrice.toStringAsFixed(2)}'
                          : 'Pending',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: totalPrice > 0
                            ? Colors.teal.shade600
                            : Colors.orange.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // PRESCRIPTION VIEW (Fixed zoom/pan)
  // ════════════════════════════════════════
  Widget _buildPrescriptionView(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final notes = widget.order['notes'] ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prescriptions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Image viewer ──
          if (_loadingImages)
            const Expanded(
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_prescriptionImages.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_not_supported_rounded,
                      size: 48,
                      color: subtextColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No prescriptions found',
                      style: TextStyle(color: subtextColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: PageView.builder(
                controller: _imagePageController,
                onPageChanged: (i) => setState(() => _currentImagePage = i),
                // ── KEY FIX: Disable swipe when zoomed ──
                physics: (_isZoomed[_currentImagePage] ?? false)
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                itemCount: _prescriptionImages.length,
                itemBuilder: (context, index) {
                  final imagePath =
                      _prescriptionImages[index]['image_url'] as String;
                  final zoomCtrl = _zoomFor(index);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: InteractiveViewer(
                        transformationController: zoomCtrl,
                        minScale: 1.0,
                        maxScale: 5.0,
                        // ── KEY FIX: Allow panning within bounds ──
                        boundaryMargin: const EdgeInsets.all(200),
                        panEnabled: true,
                        scaleEnabled: true,
                        onInteractionEnd: (_) {
                          // ── Snap back to normal if barely zoomed ──
                          if (zoomCtrl.value.getMaxScaleOnAxis() < 1.05) {
                            zoomCtrl.value = Matrix4.identity();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade900
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FutureBuilder<String>(
                            future: _getSignedUrl(imagePath),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              }
                              return Image.network(
                                snapshot.data!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    size: 48,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Page dots ──
            if (_prescriptionImages.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_prescriptionImages.length, (i) {
                  final isActive = i == _currentImagePage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isActive ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isActive
                          ? Colors.teal.shade600
                          : Colors.teal.shade600.withOpacity(0.2),
                    ),
                  );
                }),
              ),
            ],

            // ── Zoom hint ──
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Pinch to zoom  •  Swipe to change',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
            ),
          ],

          // ── Notes ──
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF222222)
                    : const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: subtextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notes,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // HELPER WIDGETS
  // ════════════════════════════════════════
  Widget _buildCodeBox(String code, bool isDark) {
    final digits = code.split('');

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.teal.shade900.withOpacity(0.25)
                : Colors.teal.shade50.withOpacity(0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.teal.shade400.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 15,
                    color: Colors.teal.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Show to delivery person',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: digits.map((d) {
                  return Container(
                    width: 46,
                    height: 54,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.teal.shade400, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveredBadge(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.green.shade900.withOpacity(0.2)
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade600,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Verified & Delivered',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCodeBadge(bool isDark, Color subtextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.pin_rounded, size: 18, color: subtextColor),
          const SizedBox(width: 10),
          Text(
            'Delivery Code',
            style: TextStyle(fontSize: 13, color: subtextColor),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Pending',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: subtextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    double amount,
    Color textColor,
    Color subtextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: subtextColor)),
        Text(
          amount > 0 ? 'LKR ${amount.toStringAsFixed(2)}' : '-',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
