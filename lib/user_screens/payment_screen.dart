import 'package:flutter/material.dart';
import '../main.dart';
import 'order_tracking_popup.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  _buildBackArrow(isDark),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payments',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your order payments',
                          style: TextStyle(fontSize: 14, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Orders
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
                            ),
                          );
                        }

                        final allOrders = snapshot.data ?? [];
                        if (allOrders.isEmpty) return _buildEmptyState(isDark);

                        final pendingPayment = allOrders
                            .where(
                              (o) => [
                                'price_confirmed',
                                'preparing',
                                'out_for_delivery',
                              ].contains(o['status']),
                            )
                            .toList();

                        final awaitingPrice = allOrders
                            .where(
                              (o) => [
                                'order_placed',
                                'pharmacist_verified',
                              ].contains(o['status']),
                            )
                            .toList();

                        final completed = allOrders
                            .where((o) => o['status'] == 'delivered')
                            .toList();

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (pendingPayment.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'To Pay',
                                  pendingPayment.length,
                                  Colors.orange,
                                  isDark,
                                ),
                                const SizedBox(height: 12),
                                ...pendingPayment.map(
                                  (o) => _buildPaymentCard(
                                    o,
                                    isDark,
                                    textColor,
                                    subtextColor,
                                    cardBg,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              if (awaitingPrice.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'Awaiting Price',
                                  awaitingPrice.length,
                                  Colors.blue,
                                  isDark,
                                ),
                                const SizedBox(height: 12),
                                ...awaitingPrice.map(
                                  (o) => _buildAwaitingCard(
                                    o,
                                    isDark,
                                    textColor,
                                    subtextColor,
                                    cardBg,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              if (completed.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'Paid',
                                  completed.length,
                                  Colors.green,
                                  isDark,
                                ),
                                const SizedBox(height: 12),
                                ...completed.map(
                                  (o) => _buildCompletedCard(
                                    o,
                                    isDark,
                                    textColor,
                                    subtextColor,
                                    cardBg,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              const SizedBox(height: 40),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== HELPER WIDGETS =====

  Widget _buildBackArrow(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.teal.shade900.withOpacity(0.3)
              : Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: Colors.teal.shade600,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count,
    Color color,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ===== PAYMENT CARD (To Pay) =====

  Widget _buildPaymentCard(
    Map<String, dynamic> order,
    bool isDark,
    Color textColor,
    Color subtextColor,
    Color cardBg,
  ) {
    final orderName = order['order_name'] ?? 'My Order';
    final orderId = order['id']?.toString().substring(0, 8).toUpperCase() ?? '';
    final pharmacyName = order['pharmacy_name'] ?? 'Pharmacy';
    final status = order['status'] ?? '';
    final statusConfig = _getStatusConfig(status);
    final showCode = status == 'out_for_delivery';
    final verificationCode = order['verification_code']?.toString() ?? '----';

    // Parse prices safely
    final double totalPrice = _parseDouble(order['total_price']);
    final double medicineCost = _parseDouble(order['medicine_cost']);
    final double deliveryFee = _parseDouble(order['delivery_fee']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#ORD-$orderId  •  $pharmacyName',
                      style: TextStyle(fontSize: 13, color: subtextColor),
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

          const SizedBox(height: 16),

          // Price Breakdown
          _buildPriceRow('Medicine Cost', medicineCost, isDark, subtextColor),
          const SizedBox(height: 8),
          _buildPriceRow('Delivery Fee', deliveryFee, isDark, subtextColor),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),

          // Total
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
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: totalPrice > 0
                      ? Colors.teal.shade600
                      : Colors.orange.shade600,
                ),
              ),
            ],
          ),

          // Verification Code
          if (showCode) ...[
            const SizedBox(height: 16),
            _buildVerificationCodeBox(verificationCode, isDark),
          ],

          const SizedBox(height: 16),

          // Track Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => OrderTrackingPopup.show(context, order),
              icon: const Icon(Icons.location_on_rounded, size: 18),
              label: const Text(
                'Track Order',
                style: TextStyle(fontWeight: FontWeight.w600),
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
        ],
      ),
    );
  }

  // ===== AWAITING CARD =====

  Widget _buildAwaitingCard(
    Map<String, dynamic> order,
    bool isDark,
    Color textColor,
    Color subtextColor,
    Color cardBg,
  ) {
    final orderName = order['order_name'] ?? 'My Order';
    final orderId = order['id']?.toString().substring(0, 8).toUpperCase() ?? '';
    final pharmacyName = order['pharmacy_name'] ?? 'Pharmacy';
    final status = order['status'] ?? '';
    final statusConfig = _getStatusConfig(status);

    return GestureDetector(
      onTap: () => OrderTrackingPopup.show(context, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                color: Colors.blue,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#ORD-$orderId  •  $pharmacyName',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (statusConfig['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Pending',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusConfig['color'] as Color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== COMPLETED CARD =====

  Widget _buildCompletedCard(
    Map<String, dynamic> order,
    bool isDark,
    Color textColor,
    Color subtextColor,
    Color cardBg,
  ) {
    final orderName = order['order_name'] ?? 'My Order';
    final orderId = order['id']?.toString().substring(0, 8).toUpperCase() ?? '';
    final double totalPrice = _parseDouble(order['total_price']);
    final createdAt = order['created_at'] != null
        ? DateTime.parse(order['created_at'])
        : DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr = '${months[createdAt.month - 1]} ${createdAt.day}';

    return GestureDetector(
      onTap: () => OrderTrackingPopup.show(context, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.green.shade900.withOpacity(0.1)
              : Colors.green.shade50.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.green.shade600,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '#ORD-$orderId  •  $dateStr',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),
            Text(
              totalPrice > 0 ? 'LKR ${totalPrice.toStringAsFixed(0)}' : '-',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== VERIFICATION CODE BOX =====

  Widget _buildVerificationCodeBox(String code, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.teal.shade900.withOpacity(0.2)
            : Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade300),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: code.split('').map((d) {
              return Container(
                width: 44,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade400, width: 2),
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
    );
  }

  // ===== PRICE ROW =====

  Widget _buildPriceRow(
    String label,
    double amount,
    bool isDark,
    Color subtextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: subtextColor)),
        Text(
          amount > 0 ? 'LKR ${amount.toStringAsFixed(2)}' : '-',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  // ===== EMPTY STATE =====

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payments_outlined,
            size: 72,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No payments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your order payments will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // ===== SAFE PARSE =====

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ===== STATUS CONFIG =====

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'order_placed':
        return {'label': 'Order Placed', 'color': Colors.blue};
      case 'pharmacist_verified':
        return {'label': 'Verified', 'color': Colors.purple};
      case 'price_confirmed':
        return {'label': 'To Pay', 'color': Colors.orange};
      case 'preparing':
        return {'label': 'Preparing', 'color': Colors.orange};
      case 'out_for_delivery':
        return {'label': 'Out for Delivery', 'color': Colors.blue};
      case 'delivered':
        return {'label': 'Paid', 'color': Colors.green};
      default:
        return {'label': 'Pending', 'color': Colors.grey};
    }
  }
}
