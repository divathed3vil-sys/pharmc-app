import 'package:flutter/material.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Fake data — will come from Supabase later
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
          'My Orders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
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
              unselectedLabelColor: Colors.grey.shade500,
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
          // Active orders tab
          _buildActiveTab(),
          // History tab
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // Active orders tab
  Widget _buildActiveTab() {
    if (_activeOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No active orders',
        subtitle: 'Your current orders will appear here',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _activeOrders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = _activeOrders[index];
        return _buildActiveOrderCard(order);
      },
    );
  }

  // History tab
  Widget _buildHistoryTab() {
    if (_pastOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No order history',
        subtitle: 'Your completed orders will appear here',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _pastOrders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _pastOrders[index];
        return _buildHistoryOrderCard(order);
      },
    );
  }

  // Active order card with progress tracker
  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    final steps = order['steps'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order['date'] as String,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
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

          // Pharmacy and prescription info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                Text(
                  '${order['prescriptions']} prescription(s)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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

            // Find the current active step
            final isCurrentStep =
                isDone && (isLast || !(steps[stepIndex + 1]['done'] as bool));

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step indicator column
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
                            : Colors.grey.shade200,
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
                            : Colors.grey.shade200,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Step label
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
                          ? (isCurrentStep
                                ? Colors.teal.shade800
                                : const Color(0xFF1A1A1A))
                          : Colors.grey.shade400,
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
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              Text(
                order['total'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: order['total'] == 'Pending'
                      ? Colors.orange.shade600
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // History order card (simpler, no progress tracker)
  Widget _buildHistoryOrderCard(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Status icon
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

          // Order info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['pharmacy'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order['id']}  •  ${order['date']}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order['prescriptions']} prescription(s)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),

          // Price and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order['total'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
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

  // Empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
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
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
