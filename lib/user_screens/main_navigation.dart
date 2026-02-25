import 'package:flutter/material.dart';
import '../main.dart';
import 'home_screen.dart';
import 'payment_screen.dart';
import 'orders_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _selectedIndex = 1; // Start at Home (center)

  // Pulse animation for payment hint
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  bool _hasPaymentPending = false;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 1);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnim = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed && _hasPaymentPending) {
        _pulseController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updatePaymentState(List<Map<String, dynamic>> orders) {
    final hasPending = orders.any((o) => o['status'] == 'price_confirmed');

    if (hasPending == _hasPaymentPending) return;

    setState(() {
      _hasPaymentPending = hasPending;
    });

    if (hasPending) {
      _pulseController.forward();
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      body: Stack(
        children: [
          // ───────── PageView (Swipe Navigation) ─────────
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: const [
              PaymentScreen(), // 0
              HomeScreen(), // 1 (default)
              OrdersScreen(), // 2
            ],
          ),

          // ───────── Invisible Orders Stream ─────────
          if (userId != null)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('orders')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', userId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updatePaymentState(snapshot.data!);
                  });
                }
                return const SizedBox.shrink();
              },
            ),

          // ───────── Payment Hint Arrow (only on Home) ─────────
          if (_selectedIndex == 1)
            Positioned(
              bottom: 120,
              left: 0,
              child: _buildPaymentArrow(context),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.payment_rounded, 'Payment', 0),
              _buildNavItem(Icons.home_rounded, 'Home', 1),
              _buildNavItem(Icons.receipt_long_rounded, 'Orders', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentArrow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double opacity = _hasPaymentPending ? 0.85 : 0.15;

    return GestureDetector(
      onTap: () => _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ),
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 600),
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            final dx = _hasPaymentPending ? _pulseAnim.value : 0.0;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 10, 10, 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.teal.shade800.withOpacity(0.9)
                  : Colors.teal.shade600,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: _hasPaymentPending
                  ? [
                      BoxShadow(
                        color: Colors.teal.shade400.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(2, 0),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _hasPaymentPending
                      ? Icons.payments_rounded
                      : Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                if (_hasPaymentPending) ...[
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
