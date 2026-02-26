import 'package:flutter/material.dart';
import '../main.dart';
import 'order_tracking_popup.dart';

import '../services/draft_order_service.dart';
import '../services/verification_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  bool _isApproved = false;
  bool _statusLoading = true;

  // Drafts
  bool _draftsLoading = true;
  List<DraftOrder> _draftOrders = [];
  bool _showDraftsTab = false;

  final _activeStatuses = [
    'order_placed',
    'pharmacist_verified',
    'price_confirmed',
    'preparing',
    'out_for_delivery',
  ];
  final _pastStatuses = ['delivered', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _initTabs();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _initTabs() async {
    setState(() => _statusLoading = true);

    final approved = await VerificationService.isApproved();
    final drafts = await DraftOrderService.getDraftOrders();

    if (!mounted) return;

    _isApproved = approved;
    _draftOrders = drafts;
    _draftsLoading = false;

    // Behavior B:
    // Drafts tab exists only if drafts exist (even if verified)
    _showDraftsTab = _draftOrders.isNotEmpty;

    _statusLoading = false;

    _tabController?.dispose();
    _tabController = TabController(length: _showDraftsTab ? 4 : 3, vsync: this);

    setState(() {});
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
          'color': Colors.orange,
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
    final bgColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final tabBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);
    final userId = supabase.auth.currentUser?.id;

    if (_tabController == null || _statusLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.teal.shade600,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final tabs = _showDraftsTab
        ? const [
            Tab(text: 'Recent'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
            Tab(text: 'Drafts'),
          ]
        : const [
            Tab(text: 'Recent'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ];

    final views = <Widget>[
      _buildOrderStream(
        userId: userId,
        filterFn: (_) => true,
        limit: 5,
        emptyTitle: 'No recent orders',
        emptySubtitle: 'Your latest orders will appear here',
        emptyIcon: Icons.receipt_long_outlined,
        isDark: isDark,
        textColor: textColor,
        cardType: 'compact',
      ),
      _buildOrderStream(
        userId: userId,
        filterFn: (status) => _activeStatuses.contains(status),
        emptyTitle: 'No active orders',
        emptySubtitle: 'Current orders will appear here',
        emptyIcon: Icons.local_shipping_outlined,
        isDark: isDark,
        textColor: textColor,
        cardType: 'detailed',
      ),
      _buildOrderStream(
        userId: userId,
        filterFn: (status) => _pastStatuses.contains(status),
        emptyTitle: 'No order history',
        emptySubtitle: 'Completed orders will appear here',
        emptyIcon: Icons.history_rounded,
        isDark: isDark,
        textColor: textColor,
        cardType: 'compact',
      ),
    ];

    if (_showDraftsTab) {
      views.add(_buildDraftsTab(isDark, textColor));
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + refresh
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Orders',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _initTabs,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: tabBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.teal.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: isDark
                    ? Colors.grey.shade500
                    : Colors.grey.shade500,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: tabs,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: views,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------
  // Drafts tab
  // ------------------------------
  Widget _buildDraftsTab(bool isDark, Color textColor) {
    final subtextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;

    if (_draftsLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.teal.shade600,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_draftOrders.isEmpty) {
      return _buildEmpty(
        'No drafts',
        'Draft orders saved before verification appear here',
        Icons.drafts_outlined,
        isDark,
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: _draftOrders.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildDraftBanner(isDark, textColor, subtextColor);
        }
        final d = _draftOrders[index - 1];
        return _buildDraftCard(d, isDark, textColor, subtextColor);
      },
    );
  }

  Widget _buildDraftBanner(bool isDark, Color textColor, Color subtextColor) {
    final color = _isApproved ? Colors.green : Colors.orange;
    final icon = _isApproved
        ? Icons.verified_rounded
        : Icons.lock_clock_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isApproved
                  ? 'You are verified. You can place these demo orders now (Home will show the option).'
                  : 'You are not verified yet. Draft orders stay on this device until verification.',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftCard(
    DraftOrder d,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    final createdAt = d.createdAt;
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
      onTap: () => _showDraftPreview(d, isDark, textColor, subtextColor),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 0.5,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.drafts_rounded,
                color: Colors.orange.shade600,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.orderName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${d.pharmacyName}  •  $dateStr  •  ${d.images.length} image(s)',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                await DraftOrderService.deleteDraftOrder(d.id);
                await _initTabs(); // hides Draft tab automatically if empty
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade500,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDraftPreview(
    DraftOrder d,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.orderName,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pharmacy: ${d.pharmacyName}',
                style: TextStyle(color: subtextColor, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                'Notes: ${d.notes.isEmpty ? "-" : d.notes}',
                style: TextStyle(color: subtextColor, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: d.images.take(3).map((img) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      img.bytes,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------
  // Streams: Recent/Active/History
  // ------------------------------
  Widget _buildOrderStream({
    required String? userId,
    required bool Function(String status) filterFn,
    int? limit,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
    required bool isDark,
    required Color textColor,
    required String cardType,
  }) {
    if (userId == null) {
      return _buildEmpty(emptyTitle, emptySubtitle, emptyIcon, isDark);
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.teal.shade600,
              strokeWidth: 2.5,
            ),
          );
        }

        var orders = (snapshot.data ?? [])
            .where((o) => filterFn(o['status'] ?? ''))
            .toList();

        if (limit != null && orders.length > limit) {
          orders = orders.sublist(0, limit);
        }

        if (orders.isEmpty) {
          return _buildEmpty(emptyTitle, emptySubtitle, emptyIcon, isDark);
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final order = orders[index];
            return cardType == 'detailed'
                ? _buildActiveCard(order, isDark, textColor)
                : _buildCompactCard(order, isDark, textColor);
          },
        );
      },
    );
  }

  Widget _buildCompactCard(
    Map<String, dynamic> order,
    bool isDark,
    Color textColor,
  ) {
    final status = order['status'] ?? 'pending';
    final config = _getStatusConfig(status);
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
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final subtextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;

    return GestureDetector(
      onTap: () => OrderTrackingPopup.show(context, order),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 0.5,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$pharmacyName  •  $dateStr',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalPrice > 0
                      ? 'LKR ${totalPrice.toStringAsFixed(0)}'
                      : 'Pending',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (config['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
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
    );
  }

  Widget _buildActiveCard(
    Map<String, dynamic> order,
    bool isDark,
    Color textColor,
  ) {
    final status = order['status'] ?? 'order_placed';
    final config = _getStatusConfig(status);
    final steps = _getTrackingSteps(status);
    final orderName = order['order_name'] ?? 'My Order';
    final pharmacyName = order['pharmacy_name'] ?? 'Pharmacy';
    final totalPrice = order['total_price'] ?? 0.0;
    final orderId = order['id']?.toString().substring(0, 8).toUpperCase() ?? '';
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final innerBg = isDark ? const Color(0xFF222222) : const Color(0xFFF8F9FA);
    final subtextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;

    return GestureDetector(
      onTap: () => OrderTrackingPopup.show(context, order),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 0.5,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
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
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#ORD-$orderId',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtextColor,
                          fontWeight: FontWeight.w500,
                        ),
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
                    color: (config['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        config['icon'] as IconData,
                        size: 14,
                        color: config['color'] as Color,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        config['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: config['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // pharmacy
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: innerBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_pharmacy_rounded,
                    size: 18,
                    color: Colors.teal.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pharmacyName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // steps
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
                        width: 22,
                        height: 22,
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
                                    ? Icons.radio_button_checked
                                    : Icons.check_rounded,
                                size: 12,
                                color: isCurrent
                                    ? Colors.white
                                    : Colors.teal.shade700,
                              )
                            : null,
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 20,
                          color: isDone
                              ? Colors.teal.shade200
                              : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w400,
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

            const SizedBox(height: 14),

            // total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(fontSize: 13, color: subtextColor),
                ),
                Text(
                  totalPrice > 0
                      ? 'LKR ${totalPrice.toStringAsFixed(2)}'
                      : 'Pending',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: totalPrice > 0 ? textColor : Colors.orange.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Center(
              child: Text(
                'Tap for details →',
                style: TextStyle(
                  fontSize: 11,
                  color: subtextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
  ) {
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
              icon,
              size: 36,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
