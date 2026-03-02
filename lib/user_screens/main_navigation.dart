import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'payment_screen.dart';
import 'orders_screen.dart';

// ============================================================
// MAIN NAVIGATION
// ============================================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  late PageController _pageController;
  int _selectedIndex = 1;

  late AnimationController _navEntrance;
  late Animation<Offset> _navSlide;
  late Animation<double> _navFade;

  late AnimationController _indicatorController;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  bool _hasPaymentPending = false;

  final List<_NavItem> _navItems = const [
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

    _navEntrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _navSlide = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _navEntrance, curve: Curves.easeOutCubic),
        );

    _navFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _navEntrance,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

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

  void _onPageChanged(int index) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userId = AuthService.getCurrentUserId();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        backgroundColor: isDark
            ? const Color(0xFF0F0F0F)
            : const Color(0xFFFAFAFA),
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: const [PaymentScreen(), HomeScreen(), OrdersScreen()],
            ),

            if (userId != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabase
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

            if (_selectedIndex == 1)
              Positioned(
                bottom: 120,
                left: 0,
                child: _buildPaymentArrow(isDark),
              ),

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

  Widget _buildFloatingNav(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  width: 0.5,
                ),
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
                children: List.generate(
                  _navItems.length,
                  (index) => _buildNavItem(index, isDark),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    final isSelected = _selectedIndex == index;
    final item = _navItems[index];

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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                key: ValueKey('${index}_$isSelected'),
                color: isSelected ? selectedColor : unselectedColor,
                size: isSelected ? 24 : 22,
              ),
            ),
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
              color: isDark
                  ? Colors.teal.shade800.withOpacity(0.85)
                  : Colors.teal.shade600,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
