import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'home_screen.dart';
import 'payment_screen.dart';
import 'orders_screen.dart';

// ============================================================
// MAIN NAVIGATION
// Telegram-inspired floating glassmorphic bottom nav
// with swipeable PageView and payment pulse indicator
// ============================================================
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  // ════════════════════════════════════════
  // CONTROLLERS & STATE
  // ════════════════════════════════════════
  late PageController _pageController;
  int _selectedIndex = 1; // Start at Home (center page)

  // ── Nav bar entrance animation ──
  late AnimationController _navEntrance;
  late Animation<Offset> _navSlide;
  late Animation<double> _navFade;

  // ── Tab indicator animation ──
  late AnimationController _indicatorController;

  // ── Payment pulse animation ──
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  bool _hasPaymentPending = false;

  // ── Nav items config ──
  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Pay',
    ),
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.receipt_outlined,
      activeIcon: Icons.receipt_rounded,
      label: 'Orders',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 1);

    // ── Nav bar slides up on first load ──
    _navEntrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _navSlide = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _navEntrance, curve: Curves.easeOutCubic),
        );
    _navFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _navEntrance,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Indicator smooth transition ──
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // ── Payment pulse ──
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

    // ── Start nav entrance after a slight delay ──
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _navEntrance.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navEntrance.dispose();
    _indicatorController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════
  // PAGE CHANGE HANDLER
  // ════════════════════════════════════════
  void _onPageChanged(int index) {
    // ── Haptic feedback on page switch ──
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  // ════════════════════════════════════════
  // PAYMENT STATE LISTENER
  // ════════════════════════════════════════
  void _updatePaymentState(List<Map<String, dynamic>> orders) {
    final hasPending = orders.any((o) => o['status'] == 'price_confirmed');
    if (hasPending == _hasPaymentPending) return;

    setState(() => _hasPaymentPending = hasPending);

    if (hasPending) {
      _pulseController.forward();
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  // ════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = supabase.auth.currentUser?.id;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        // ── Transparent so floating nav shows over content ──
        extendBody: true,
        backgroundColor: isDark
            ? const Color(0xFF0F0F0F)
            : const Color(0xFFFAFAFA),
        body: Stack(
          children: [
            // ────────────────────────────────
            // SWIPEABLE PAGES
            // ────────────────────────────────
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: const [
                PaymentScreen(), // index 0
                HomeScreen(), // index 1 (default)
                OrdersScreen(), // index 2
              ],
            ),

            // ────────────────────────────────
            // INVISIBLE ORDERS STREAM LISTENER
            // (monitors payment state for pulse)
            // ────────────────────────────────
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

            // ────────────────────────────────
            // PAYMENT HINT ARROW (Home page only)
            // ────────────────────────────────
            if (_selectedIndex == 1)
              Positioned(
                bottom: 120,
                left: 0,
                child: _buildPaymentArrow(isDark),
              ),

            // ────────────────────────────────
            // FLOATING BOTTOM NAV BAR
            // ────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _navSlide,
                child: FadeTransition(
                  opacity: _navFade,
                  child: _buildFloatingNav(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // FLOATING GLASSMORPHIC BOTTOM NAV
  // ════════════════════════════════════════
  Widget _buildFloatingNav(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            // ── Frosted glass blur effect ──
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                // ── Semi-transparent background ──
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(28),
                // ── Subtle border for depth ──
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  width: 0.5,
                ),
                // ── Soft shadow ──
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_navItems.length, (index) {
                  return _buildNavItem(index, isDark);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // INDIVIDUAL NAV ITEM
  // ════════════════════════════════════════
  Widget _buildNavItem(int index, bool isDark) {
    final isSelected = _selectedIndex == index;
    final item = _navItems[index];

    // ── Colors ──
    final selectedColor = Colors.teal.shade500;
    final unselectedColor = isDark
        ? Colors.grey.shade500
        : Colors.grey.shade400;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _goToPage(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          // ── Selected pill background ──
          color: isSelected
              ? (isDark
                    ? Colors.teal.shade700.withOpacity(0.25)
                    : Colors.teal.shade50.withOpacity(0.9))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Animated icon swap ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) {
                return ScaleTransition(scale: anim, child: child);
              },
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                key: ValueKey('${index}_$isSelected'),
                color: isSelected ? selectedColor : unselectedColor,
                size: isSelected ? 24 : 22,
              ),
            ),

            // ── Label slides in when selected ──
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selectedColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // PAYMENT HINT ARROW (left edge)
  // ════════════════════════════════════════
  Widget _buildPaymentArrow(bool isDark) {
    final double opacity = _hasPaymentPending ? 0.85 : 0.15;

    return GestureDetector(
      onTap: () => _goToPage(0),
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
              // ── Glassmorphic arrow matching nav bar ──
              color: isDark
                  ? Colors.teal.shade800.withOpacity(0.85)
                  : Colors.teal.shade600,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: _hasPaymentPending
                  ? [
                      BoxShadow(
                        color: Colors.teal.shade400.withOpacity(0.4),
                        blurRadius: 12,
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
                      ? Icons.account_balance_wallet_rounded
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

// ════════════════════════════════════════
// NAV ITEM DATA CLASS
// ════════════════════════════════════════
class _NavItem {
  final IconData icon; // Outlined version (unselected)
  final IconData activeIcon; // Filled version (selected)
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
