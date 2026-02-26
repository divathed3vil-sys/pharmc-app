import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'order_tracking_popup.dart';

// ============================================================
// PAYMENT SCREEN
// Telegram-inspired glassmorphic design
// Shows last order hero + order list with medicine details
// ============================================================
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  // ════════════════════════════════════════
  // STATE
  // ════════════════════════════════════════
  int _activeTab = 0; // 0 = Pending, 1 = Paid
  String? _expandedOrderId; // Which order card is expanded

  // ── Animations ──
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _heroController;
  late Animation<Offset> _heroSlide;
  late Animation<double> _heroFade;

  // ── Prescription viewer state ──
  final PageController _prescriptionPageController = PageController();
  int _currentPrescriptionPage = 0;
  bool _showingPrescription = false;
  String? _viewingOrderId;

  @override
  void initState() {
    super.initState();

    // ── Page fade-in ──
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // ── Hero card entrance ──
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
        );
    _heroFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _heroController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _heroController.dispose();
    _prescriptionPageController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
          'label': 'To Pay',
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
          'label': 'Paid',
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

  // ── Filter orders into pending & paid ──
  List<Map<String, dynamic>> _filterOrders(
    List<Map<String, dynamic>> orders,
    bool isPending,
  ) {
    final pendingStatuses = [
      'order_placed',
      'pharmacist_verified',
      'price_confirmed',
      'preparing',
      'out_for_delivery',
    ];
    return orders.where((o) {
      final status = o['status'] ?? '';
      return isPending
          ? pendingStatuses.contains(status)
          : status == 'delivered';
    }).toList();
  }

  // ════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ════════════════════════════════
              // HEADER
              // ════════════════════════════════
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payments',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track and manage your orders',
                      style: TextStyle(
                        fontSize: 14,
                        color: subtextColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ════════════════════════════════
              // FROSTED GLASS TAB SWITCHER
              // (Vertical layout — no swipe conflict)
              // ════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildFrostedTabs(isDark, textColor),
              ),

              const SizedBox(height: 16),

              // ════════════════════════════════
              // CONTENT
              // ════════════════════════════════
              Expanded(
                child: userId == null
                    ? _buildEmptyState(isDark)
                    : StreamBuilder<List<Map<String, dynamic>>>(
                        stream: supabase
                            .from('orders')
                            .stream(primaryKey: ['id'])
                            .eq('user_id', userId)
                            .order('created_at', ascending: false),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Colors.teal.shade600,
                                strokeWidth: 2.5,
                              ),
                            );
                          }

                          final allOrders = snapshot.data ?? [];
                          if (allOrders.isEmpty)
                            return _buildEmptyState(isDark);

                          final isPending = _activeTab == 0;
                          final filtered = _filterOrders(allOrders, isPending);

                          if (filtered.isEmpty) {
                            return _buildEmptyState(
                              isDark,
                              title: isPending
                                  ? 'No pending payments'
                                  : 'No paid orders',
                              subtitle: isPending
                                  ? 'Orders awaiting payment appear here'
                                  : 'Completed payments appear here',
                            );
                          }

                          return _buildOrderList(
                            filtered,
                            isDark,
                            textColor,
                            subtextColor,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // FROSTED GLASS TAB SWITCHER
  // ════════════════════════════════════════
  Widget _buildFrostedTabs(bool isDark, Color textColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            ),
          ),
          child: Row(
            children: [
              _buildTab(0, 'Pending', Icons.schedule_rounded, isDark),
              _buildTab(1, 'Paid', Icons.check_circle_outline_rounded, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon, bool isDark) {
    final isSelected = _activeTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? Colors.teal.shade700.withOpacity(0.35)
                      : Colors.teal.shade500)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.teal.withOpacity(isDark ? 0.15 : 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
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
  // ORDER LIST
  // First item = Hero card, rest = compact
  // ════════════════════════════════════════
  Widget _buildOrderList(
    List<Map<String, dynamic>> orders,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        if (index == 0) {
          // ── HERO CARD: First/latest order ──
          return SlideTransition(
            position: _heroSlide,
            child: FadeTransition(
              opacity: _heroFade,
              child: _buildHeroPaymentCard(
                order,
                isDark,
                textColor,
                subtextColor,
              ),
            ),
          );
        }

        // ── Regular expandable cards ──
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 80)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildExpandableCard(order, isDark, textColor, subtextColor),
        );
      },
    );
  }

  // ════════════════════════════════════════
  // HERO PAYMENT CARD (Latest order — full detail)
  // ════════════════════════════════════════
  Widget _buildHeroPaymentCard(
    Map<String, dynamic> order,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    final status = order['status'] ?? 'pending';
    final config = _getStatusConfig(status);
    final orderName = order['order_name'] ?? 'My Order';
    final orderId = order['id']?.toString().substring(0, 8).toUpperCase() ?? '';
    final pharmacyName = order['pharmacy_name'] ?? 'Pharmacy';
    final totalPrice = _parseDouble(order['total_price']);
    final medicineCost = _parseDouble(order['medicine_cost']);
    final deliveryFee = _parseDouble(order['delivery_fee']);
    final verificationCode = order['verification_code']?.toString() ?? '----';
    final showCode = status == 'out_for_delivery';

    // ── Parse medicine items if available ──
    final List<dynamic> medicines = order['medicines'] ?? [];

    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final innerBg = isDark ? const Color(0xFF222222) : const Color(0xFFF5F6F8);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                // ── Status icon ──
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (config['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    config['icon'] as IconData,
                    color: config['color'] as Color,
                    size: 22,
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
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#$orderId  •  $pharmacyName',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (config['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    config['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: config['color'] as Color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Medicine items list ──
          if (medicines.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: innerBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: subtextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...medicines.map((med) {
                      final name = med['name'] ?? 'Medicine';
                      final qty = med['quantity'] ?? 1;
                      final price = _parseDouble(med['price']);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.teal.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$name  ×$qty',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Text(
                              price > 0
                                  ? 'LKR ${price.toStringAsFixed(0)}'
                                  : '-',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Price breakdown ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: innerBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _priceRow('Subtotal', medicineCost, textColor, subtextColor),
                  const SizedBox(height: 8),
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
                          fontSize: 22,
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
          ),

          // ── Verification code ──
          if (showCode) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildVerificationCode(verificationCode, isDark),
            ),
          ],

          const SizedBox(height: 14),

          // ── Prescription thumbnails ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildPrescriptionThumbnails(order, isDark, subtextColor),
          ),

          // ── Track order button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: GestureDetector(
                    onTap: () => OrderTrackingPopup.show(context, order),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.teal.shade600.withOpacity(
                          isDark ? 0.3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: isDark
                            ? Border.all(
                                color: Colors.teal.shade500.withOpacity(0.3),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Track Order',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ],
                      ),
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
  // EXPANDABLE ORDER CARD (Other orders)
  // ════════════════════════════════════════
  Widget _buildExpandableCard(
    Map<String, dynamic> order,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    final orderId = order['id']?.toString() ?? '';
    final isExpanded = _expandedOrderId == orderId;
    final status = order['status'] ?? 'pending';
    final config = _getStatusConfig(status);
    final orderName = order['order_name'] ?? 'My Order';
    final shortId = orderId.length >= 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();
    final totalPrice = _parseDouble(order['total_price']);
    final medicineCost = _parseDouble(order['medicine_cost']);
    final deliveryFee = _parseDouble(order['delivery_fee']);
    final List<dynamic> medicines = order['medicines'] ?? [];
    final verificationCode = order['verification_code']?.toString() ?? '----';
    final showCode = status == 'out_for_delivery';

    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final innerBg = isDark ? const Color(0xFF222222) : const Color(0xFFF5F6F8);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _expandedOrderId = isExpanded ? null : orderId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? Colors.teal.shade500.withOpacity(0.3)
                : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04)),
            width: isExpanded ? 1.5 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isExpanded ? 16 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Compact header (always visible) ──
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (config['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    config['icon'] as IconData,
                    color: config['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '#$shortId',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                Text(
                  totalPrice > 0
                      ? 'LKR ${totalPrice.toStringAsFixed(0)}'
                      : 'Pending',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: totalPrice > 0 ? textColor : Colors.orange.shade500,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: subtextColor,
                    size: 22,
                  ),
                ),
              ],
            ),

            // ── Expanded content ──
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),

                  // ── Medicines ──
                  if (medicines.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: innerBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: medicines.map((med) {
                          final name = med['name'] ?? 'Medicine';
                          final qty = med['quantity'] ?? 1;
                          final price = _parseDouble(med['price']);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$name  ×$qty',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  price > 0
                                      ? 'LKR ${price.toStringAsFixed(0)}'
                                      : '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  if (medicines.isNotEmpty) const SizedBox(height: 10),

                  // ── Price breakdown ──
                  _priceRow('Subtotal', medicineCost, textColor, subtextColor),
                  const SizedBox(height: 4),
                  _priceRow('Delivery', deliveryFee, textColor, subtextColor),
                  Divider(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        totalPrice > 0
                            ? 'LKR ${totalPrice.toStringAsFixed(2)}'
                            : 'Pending',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: totalPrice > 0
                              ? Colors.teal.shade600
                              : Colors.orange.shade500,
                        ),
                      ),
                    ],
                  ),

                  // ── Verification code ──
                  if (showCode) ...[
                    const SizedBox(height: 12),
                    _buildVerificationCode(verificationCode, isDark),
                  ],

                  // ── Prescriptions ──
                  const SizedBox(height: 12),
                  _buildPrescriptionThumbnails(order, isDark, subtextColor),

                  // ── Track button ──
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () => OrderTrackingPopup.show(context, order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal.shade600,
                        side: BorderSide(
                          color: Colors.teal.shade500.withOpacity(0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Track Order',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 350),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // VERIFICATION CODE WIDGET
  // ════════════════════════════════════════
  Widget _buildVerificationCode(String code, bool isDark) {
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
                    size: 16,
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
                    width: 48,
                    height: 56,
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
                          fontSize: 26,
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

  // ════════════════════════════════════════
  // PRESCRIPTION THUMBNAILS (1, 2, or 3)
  // ════════════════════════════════════════
  Widget _buildPrescriptionThumbnails(
    Map<String, dynamic> order,
    bool isDark,
    Color subtextColor,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadPrescriptions(order['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222222) : const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final images = snapshot.data ?? [];
        if (images.isEmpty) {
          return Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222222) : const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No prescriptions',
                style: TextStyle(fontSize: 12, color: subtextColor),
              ),
            ),
          );
        }

        // ── Adaptive layout: 1, 2, or 3 boxes ──
        return Row(
          children: List.generate(images.length.clamp(0, 3), (index) {
            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    _showPrescriptionViewer(context, images, index, isDark),
                child: Container(
                  height: 80,
                  margin: EdgeInsets.only(
                    right: index < images.length.clamp(0, 3) - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF222222)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: FutureBuilder<String>(
                      future: _getSignedUrl(images[index]['image_url']),
                      builder: (context, urlSnap) {
                        if (!urlSnap.hasData) {
                          return Center(
                            child: Icon(
                              Icons.image_rounded,
                              color: subtextColor,
                              size: 24,
                            ),
                          );
                        }
                        return Image.network(
                          urlSnap.data!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: subtextColor,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // ════════════════════════════════════════
  // FULL-SCREEN PRESCRIPTION VIEWER
  // ════════════════════════════════════════
  void _showPrescriptionViewer(
    BuildContext context,
    List<Map<String, dynamic>> images,
    int initialIndex,
    bool isDark,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => _PrescriptionViewer(
        images: images,
        initialIndex: initialIndex,
        getSignedUrl: _getSignedUrl,
      ),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  // ════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════
  Widget _priceRow(
    String label,
    double amount,
    Color textColor,
    Color subtextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: subtextColor)),
        Text(
          amount > 0 ? 'LKR ${amount.toStringAsFixed(2)}' : '-',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _loadPrescriptions(dynamic orderId) async {
    try {
      final data = await supabase
          .from('prescription_images')
          .select()
          .eq('order_id', orderId);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  Future<String> _getSignedUrl(String path) async {
    return supabase.storage.from('prescriptions').createSignedUrl(path, 3600);
  }

  Widget _buildEmptyState(bool isDark, {String? title, String? subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 36,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title ?? 'No payments yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle ?? 'Your order payments will appear here',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// PRESCRIPTION VIEWER (Full-screen glassmorphic overlay)
// Supports swipe between images + 2-finger zoom/pan
// ════════════════════════════════════════════════════════════════
class _PrescriptionViewer extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;
  final Future<String> Function(String) getSignedUrl;

  const _PrescriptionViewer({
    required this.images,
    required this.initialIndex,
    required this.getSignedUrl,
  });

  @override
  State<_PrescriptionViewer> createState() => _PrescriptionViewerState();
}

class _PrescriptionViewerState extends State<_PrescriptionViewer> {
  late PageController _pageController;
  int _currentPage = 0;
  final Map<int, TransformationController> _zoomControllers = {};
  final Map<int, bool> _isZoomed = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // ── Blurred background ──
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withOpacity(isDark ? 0.7 : 0.5),
              ),
            ),
          ),

          // ── Image pages ──
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ── Counter ──
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_currentPage + 1} / ${widget.images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Close button ──
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Image viewer ──
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    // ── Disable page swipe when zoomed ──
                    physics: (_isZoomed[_currentPage] ?? false)
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    itemCount: widget.images.length,
                    itemBuilder: (context, index) {
                      final imagePath =
                          widget.images[index]['image_url'] as String;
                      final zoomCtrl = _zoomFor(index);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: InteractiveViewer(
                            transformationController: zoomCtrl,
                            minScale: 1.0,
                            maxScale: 5.0,
                            // ── KEY FIX: Boundary margin allows
                            //    panning when zoomed ──
                            boundaryMargin: const EdgeInsets.all(200),
                            panEnabled: true,
                            scaleEnabled: true,
                            onInteractionEnd: (details) {
                              // ── Snap back if barely zoomed ──
                              if (zoomCtrl.value.getMaxScaleOnAxis() < 1.05) {
                                zoomCtrl.value = Matrix4.identity();
                              }
                            },
                            child: FutureBuilder<String>(
                              future: widget.getSignedUrl(imagePath),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey.shade900
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
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
                      );
                    },
                  ),
                ),

                // ── Page dots ──
                if (widget.images.length > 1) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.images.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isActive ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                ],

                // ── Zoom hint ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Pinch to zoom  •  Swipe to change',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
