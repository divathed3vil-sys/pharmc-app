import 'package:flutter/material.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _activeOrders = [
    {
      'id': '#ORD-003',
      'pharmacy': 'MediCare Pharmacy',
      'date': 'Feb 17, 2025',
      'total': 'Rs. 850',
      'prescriptions': 2,
      'status': 'Out for Delivery',
      'statusColor': Colors.blue,
      'statusIcon': Icons.delivery_dining_rounded,
      'steps': [
        {'label': 'Order Placed', 'done': true},
        {'label': 'Pharmacist Verified', 'done': true},
        {'label': 'Price Accepted', 'done': true},
        {'label': 'Preparing', 'done': true},
        {'label': 'Out for Delivery', 'done': true},
        {'label': 'Delivered', 'done': false},
      ],
    },
    {
      'id': '#ORD-004',
      'pharmacy': 'Any Pharmacy',
      'date': 'Feb 18, 2025',
      'total': 'Pending',
      'prescriptions': 1,
      'status': 'Pending Review',
      'statusColor': Colors.orange,
      'statusIcon': Icons.access_time_rounded,
      'steps': [
        {'label': 'Order Placed', 'done': true},
        {'label': 'Pharmacist Verified', 'done': false},
        {'label': 'Price Accepted', 'done': false},
        {'label': 'Preparing', 'done': false},
        {'label': 'Out for Delivery', 'done': false},
        {'label': 'Delivered', 'done': false},
      ],
    },
  ];

  final List<Map<String, dynamic>> _pastOrders = [
    {
      'id': '#ORD-001',
      'pharmacy': 'City Pharmacy',
      'date': 'Feb 15, 2025',
      'total': 'Rs. 1,250',
      'prescriptions': 1,
      'status': 'Delivered',
      'statusColor': Colors.green,
      'statusIcon': Icons.check_circle_rounded,
    },
    {
      'id': '#ORD-002',
      'pharmacy': 'HealthPlus Pharmacy',
      'date': 'Feb 14, 2025',
      'total': 'Rs. 2,100',
      'prescriptions': 3,
      'status': 'Delivered',
      'statusColor': Colors.green,
      'statusIcon': Icons.check_circle_rounded,
    },
    {
      'id': '#ORD-000',
      'pharmacy': 'City Pharmacy',
      'date': 'Feb 10, 2025',
      'total': 'Rs. 450',
      'prescriptions': 1,
      'status': 'Cancelled',
      'statusColor': Colors.red,
      'statusIcon': Icons.cancel_rounded,
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color backBg = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF5F5F5);
    final Color tabBg = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF5F5F5);

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
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Active'),
                      if (_activeOrders.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_activeOrders.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'History'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(isDark, textColor),
          _buildHistoryTab(isDark, textColor),
        ],
      ),
    );
  }

  Widget _buildActiveTab(bool isDark, Color textColor) {
    if (_activeOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No active orders',
        subtitle: 'Your current orders will appear here',
        isDark: isDark,
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _activeOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = _activeOrders[index];
        return _buildActiveOrderCard(order, isDark, textColor);
      },
    );
  }

  Widget _buildHistoryTab(bool isDark, Color textColor) {
    if (_pastOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No order history',
        subtitle: 'Your completed orders will appear here',
        isDark: isDark,
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _pastOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _pastOrders[index];
        return _buildHistoryOrderCard(order, isDark, textColor);
      },
    );
  }

  Widget _buildActiveOrderCard(
    Map<String, dynamic> order,
    bool isDark,
    Color textColor,
  ) {
    final steps = order['steps'] as List<Map<String, dynamic>>;
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color innerCardColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF8F9FA);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
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
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['id'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order['date'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (order['statusColor'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      order['statusIcon'] as IconData,
                      size: 16,
                      color: order['statusColor'] as Color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order['status'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: order['statusColor'] as Color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Pharmacy info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: innerCardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  order['pharmacy'] == 'Any Pharmacy'
                      ? Icons.near_me_rounded
                      : Icons.local_pharmacy_rounded,
                  size: 20,
                  color: Colors.teal.shade600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order['pharmacy'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                Text(
                  '${order['prescriptions']} prescription(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Progress stepper
          ...steps.asMap().entries.map((entry) {
            final stepIndex = entry.key;
            final step = entry.value;
            final isDone = step['done'] as bool;
            final isLast = stepIndex == steps.length - 1;
            final isCurrentStep =
                isDone && (isLast || !(steps[stepIndex + 1]['done'] as bool));

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
                            ? (isCurrentStep
                                  ? Colors.teal.shade600
                                  : Colors.teal.shade100)
                            : (isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200),
                        shape: BoxShape.circle,
                      ),
                      child: isDone
                          ? Icon(
                              isCurrentStep
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.check_rounded,
                              size: 14,
                              color: isCurrentStep
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
                      fontWeight: isCurrentStep
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isDone
                          ? (isCurrentStep ? Colors.teal.shade800 : textColor)
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
          // Price row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
              Text(
                order['total'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: order['total'] == 'Pending'
                      ? Colors.orange.shade600
                      : textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryOrderCard(
    Map<String, dynamic> order,
    bool isDark,
    Color textColor,
  ) {
    final Color cardColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF8F9FA);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (order['statusColor'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              order['statusIcon'] as IconData,
              color: order['statusColor'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['pharmacy'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order['id']} • ${order['date']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order['prescriptions']} prescription(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order['total'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order['status'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: order['statusColor'] as Color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
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
