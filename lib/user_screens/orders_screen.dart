import 'package:flutter/material.dart';
import '../main.dart';
import 'order_tracking_popup.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Active statuses
  final _activeStatuses = [
    'order_placed',
    'pharmacist_verified',
    'price_confirmed',
    'preparing',
    'out_for_delivery',
  ];

  // Past statuses
  final _pastStatuses = ['delivered', 'cancelled'];

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

  List<Map<String, dynamic>> _getTrackingSteps(String status) {
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
        'done': entry.key <= currentIndex,
        'isCurrent': entry.key == currentIndex,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final backBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final tabBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final userId = supabase.auth.currentUser?.id;

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
          'My Orders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: tabBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.teal.shade600,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade500,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersStream(userId, true, isDark, textColor),
          _buildOrdersStream(userId, false, isDark, textColor),
        ],
      ),
    );
  }

  Widget _buildOrdersStream(
    String? userId,
    bool isActive,
    bool isDark,
    Color textColor,
  ) {
    if (userId == null) return _buildEmptyState(isActive, isDark);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Colors.teal.shade600),
          );
        }

        final allOrders = snapshot.data ?? [];

        // Filter based on tab
        final orders = allOrders.where((o) {
          final status = o['status'] ?? '';
          return isActive
              ? _activeStatuses.contains(status)
              : _pastStatuses.contains(status);
        }).toList();

        if (orders.isEmpty) return _buildEmptyState(isActive, isDark);

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final order = orders[index];
            return isActive
                ? _buildActiveCard(order, isDark, textColor)
                : _buildHistoryCard(order, isDark, textColor);
          },
        );
      },
    );
  }

  Widget _buildActiveCard(
    Map<String, dynamic> order,
    bool isDark,
    Color textColor,
  ) {
    final status = order['status'] ?? 'order_placed';
    final statusConfig = _getStatusConfig(status);
    final steps = _getTrackingSteps(status);
    final orderName = order['order_name'] ?? 'My Order';
    final pharmacyName = order['pharmacy_name'] ?? 'Pharmacy';
    final totalPrice = order['total_price'] ?? 0.0;
    final orderId = order['id']?.toString().substring(0, 8).toUpperCase() ?? '';
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final innerBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA);
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return GestureDetector(
      onTap: () => OrderTrackingPopup.show(context, order),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#ORD-$orderId',
                        style: TextStyle(fontSize: 13, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (statusConfig['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusConfig['icon'] as IconData,
                        size: 16,
                        color: statusConfig['color'] as Color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusConfig['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusConfig['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pharmacy
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: innerBg,
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
                  Text(
                    pharmacyName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Steps
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
                    padding: const EdgeInsets.only(top: 2),
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

            const SizedBox(height: 16),

            // Price + Tap hint
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(fontSize: 14, color: subtextColor),
                ),
                Text(
                  totalPrice > 0
                      ? 'LKR ${totalPrice.toStringAsFixed(2)}'
                      : 'Pending',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: totalPrice > 0 ? textColor : Colors.orange.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                'Tap for details',
                style: TextStyle(fontSize: 11, color: subtextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    Map<String, dynamic> order,
    bool isDark,
    Color textColor,
  ) {
    final status = order['status'] ?? '';
    final statusConfig = _getStatusConfig(status);
    final orderName = order['order_name'] ?? 'My Order';
    final pharmacyName = order['pharmacy_name'] ?? 'Pharmacy';
    final totalPrice = order['total_price'] ?? 0.0;
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (statusConfig['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                statusConfig['icon'] as IconData,
                color: statusConfig['color'] as Color,
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
                    '$pharmacyName • $dateStr',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalPrice > 0 ? 'LKR ${totalPrice.toStringAsFixed(0)}' : '-',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusConfig['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusConfig['color'] as Color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isActive, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive
                ? Icons.local_shipping_outlined
                : Icons.receipt_long_outlined,
            size: 72,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isActive ? 'No active orders' : 'No order history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isActive
                ? 'Your current orders will appear here'
                : 'Completed orders will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
