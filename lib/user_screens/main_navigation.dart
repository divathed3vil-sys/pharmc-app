import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'payment_screen.dart';
import '../main.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPage = 1; // 0 = Payment, 1 = Home

  // Pulse animation controller — only runs when payment is needed
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Whether the payment screen has orders that need attention
  bool _hasPaymentPending = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Gentle bounce: slides 0 → 10px → 0, loops
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
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  /// Called every time the orders stream emits. We check if any order is at
  /// 'price_confirmed' — meaning the admin has set a price and the user needs
  /// to go to the payment screen to review/confirm it.
  void _updatePaymentState(List<Map<String, dynamic>> orders) {
    final hasPending = orders.any((o) => o['status'] == 'price_confirmed');

    if (hasPending == _hasPaymentPending) return; // nothing changed

    setState(() => _hasPaymentPending = hasPending);

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
          // ── Page View ──────────────────────────────────────────────────
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: const [
              PaymentScreen(), // Page 0 — left
              HomeScreen(), // Page 1 — default / center
            ],
          ),

          // ── Orders stream (invisible — just drives arrow animation) ───
          if (userId != null)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('orders')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', userId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // Schedule after current frame so no setState-during-build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updatePaymentState(snapshot.data!);
                  });
                }
                return const SizedBox.shrink(); // renders nothing
              },
            ),

          // ── Payment hint arrow (only on Home screen) ──────────────────
          if (_currentPage == 1)
            Positioned(
              // Bottom-left edge — well clear of all home screen content
              bottom: 120,
              left: 0,
              child: _buildPaymentArrow(context),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentArrow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // When there's a payment pending: full opacity + bouncing animation.
    // When idle: barely visible, static — just enough to be discoverable.
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
            // Bounce rightward when payment is pending, static otherwise
            final dx = _hasPaymentPending ? _pulseAnim.value : 0.0;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 10, 10, 10),
            decoration: BoxDecoration(
              // Subtle pill tab on the left edge
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
                  // Shows a badge-style indicator when payment is pending
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
