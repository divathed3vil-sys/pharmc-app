import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/preferences_service.dart';
import 'upload_prescription_screen.dart';
import 'profile/profile_screen.dart';
import 'explore_products_screen.dart';

// ============================================================
// HOME SCREEN — Telegram-inspired modern pharmacy UI
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ── Animation Controllers ──
  late AnimationController _fadeController;
  late AnimationController _heroController;
  late AnimationController _gridController;
  late AnimationController _exploreGlowController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _heroSlide;
  late Animation<double> _heroScale;
  late Animation<double> _exploreGlow;

  // ── Sample products data (replace with Supabase later) ──
  final List<Map<String, dynamic>> _featuredProducts = [
    {
      'name': 'Vitamin C 1000mg',
      'category': 'Supplements',
      'price': 850.0,
      'icon': Icons.wb_sunny_rounded,
      'color': Colors.orange,
    },
    {
      'name': 'Hand Sanitizer',
      'category': 'Hygiene',
      'price': 350.0,
      'icon': Icons.clean_hands_rounded,
      'color': Colors.blue,
    },
    {
      'name': 'Moisturizer SPF30',
      'category': 'Skincare',
      'price': 1200.0,
      'icon': Icons.face_retouching_natural_rounded,
      'color': Colors.pink,
    },
    {
      'name': 'Digital Thermometer',
      'category': 'Devices',
      'price': 2500.0,
      'icon': Icons.thermostat_rounded,
      'color': Colors.teal,
    },
    {
      'name': 'First Aid Kit',
      'category': 'Essentials',
      'price': 3200.0,
      'icon': Icons.medical_services_rounded,
      'color': Colors.red,
    },
    {
      'name': 'Omega-3 Fish Oil',
      'category': 'Supplements',
      'price': 1800.0,
      'icon': Icons.water_drop_rounded,
      'color': Colors.indigo,
    },
  ];

  @override
  void initState() {
    super.initState();

    // ── Staggered fade-in for the entire page ──
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // ── Hero card entrance animation ──
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
        );
    _heroScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );

    // ── Grid stagger animation ──
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // ── Explore button glow pulse ──
    _exploreGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _exploreGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _exploreGlowController, curve: Curves.easeInOut),
    );

    // ── Start animations in sequence ──
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _heroController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _gridController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _exploreGlowController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _heroController.dispose();
    _gridController.dispose();
    _exploreGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = PreferencesService.getUserName() ?? 'User';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Theme-aware colors ──
    final bgColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final surfaceColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF0F0F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ════════════════════════════════════════
              // TOP BAR — Greeting + Avatar
              // ════════════════════════════════════════
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      // ── Greeting ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: subtextColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Notification bell (decorative) ──
                      _buildIconButton(
                        icon: Icons.notifications_none_rounded,
                        isDark: isDark,
                        surfaceColor: surfaceColor,
                        textColor: textColor,
                        onTap: () {},
                      ),

                      const SizedBox(width: 10),

                      // ── Profile avatar ──
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          _smoothRoute(const ProfileScreen()),
                        ),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.shade400,
                                Colors.teal.shade700,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ════════════════════════════════════════
              // HERO CARD — Upload Prescription
              // ════════════════════════════════════════
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _heroSlide,
                  child: ScaleTransition(
                    scale: _heroScale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildHeroCard(isDark, textColor),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ════════════════════════════════════════
              // QUICK ACTIONS ROW
              // ════════════════════════════════════════
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildQuickActions(
                    isDark,
                    cardColor,
                    textColor,
                    subtextColor,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ════════════════════════════════════════
              // SECTION HEADER — Health & Wellness
              // ════════════════════════════════════════
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Health & Wellness',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),

                      // ── EXPLORE BUTTON (Psychologically important) ──
                      _buildExploreButton(isDark),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ════════════════════════════════════════
              // PRODUCTS GRID (2 columns, no swipe conflict)
              // ════════════════════════════════════════
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    // ── Stagger animation per card ──
                    final delay = index * 0.15;
                    final itemAnim = CurvedAnimation(
                      parent: _gridController,
                      curve: Interval(
                        delay.clamp(0.0, 0.7),
                        (delay + 0.3).clamp(0.0, 1.0),
                        curve: Curves.easeOutCubic,
                      ),
                    );

                    return AnimatedBuilder(
                      animation: itemAnim,
                      builder: (context, child) {
                        return Opacity(
                          opacity: itemAnim.value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - itemAnim.value)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildProductCard(
                        _featuredProducts[index],
                        isDark,
                        cardColor,
                        textColor,
                        subtextColor,
                      ),
                    );
                  }, childCount: _featuredProducts.length),
                ),
              ),

              // ── Bottom padding ──
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // HERO CARD WIDGET
  // ════════════════════════════════════════
  Widget _buildHeroCard(bool isDark, Color textColor) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        _smoothRoute(const UploadPrescriptionScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade500,
              Colors.teal.shade700,
              Colors.teal.shade900,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(isDark ? 0.3 : 0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Background pattern dots ──
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.08,
                child: Icon(
                  Icons.medical_services_rounded,
                  size: 150,
                  color: Colors.white,
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon badge ──
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(height: 18),

                // ── Title ──
                const Text(
                  'Upload\nPrescription',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Snap a photo or pick from gallery',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 18),

                // ── CTA row ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Get started',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white.withOpacity(0.95),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // QUICK ACTIONS (3 chips)
  // ════════════════════════════════════════
  Widget _buildQuickActions(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    final actions = [
      {
        'icon': Icons.local_pharmacy_rounded,
        'label': 'Pharmacy',
        'color': Colors.teal,
      },
      {
        'icon': Icons.favorite_rounded,
        'label': 'Wellness',
        'color': Colors.pink,
      },
      {
        'icon': Icons.science_rounded,
        'label': 'Lab Tests',
        'color': Colors.indigo,
      },
    ];

    return Row(
      children: actions.map((action) {
        final color = action['color'] as MaterialColor;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: action != actions.last ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? color.shade900.withOpacity(0.3) : color.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? color.shade800.withOpacity(0.3)
                    : color.shade100,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  action['icon'] as IconData,
                  color: color.shade600,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  action['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade300 : textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ════════════════════════════════════════
  // EXPLORE BUTTON (Psychologically prominent)
  // ════════════════════════════════════════
  Widget _buildExploreButton(bool isDark) {
    return AnimatedBuilder(
      animation: _exploreGlow,
      builder: (context, child) {
        // ── Subtle pulsing glow to draw attention ──
        final glowOpacity = 0.15 + (_exploreGlow.value * 0.2);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            _smoothRoute(const ExploreProductsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade500, Colors.teal.shade700],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(glowOpacity),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Explore',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════
  // PRODUCT CARD WIDGET
  // ════════════════════════════════════════
  Widget _buildProductCard(
    Map<String, dynamic> product,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    final color = product['color'] as MaterialColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 0.5,
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
          // ── Product icon ──
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? color.shade900.withOpacity(0.3) : color.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              product['icon'] as IconData,
              color: color.shade600,
              size: 24,
            ),
          ),

          const Spacer(),

          // ── Category ──
          Text(
            product['category'] as String,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.shade400,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 4),

          // ── Product name ──
          Text(
            product['name'] as String,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // ── Price ──
          Text(
            'LKR ${(product['price'] as double).toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.teal.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // HELPER: Icon button
  // ════════════════════════════════════════
  Widget _buildIconButton({
    required IconData icon,
    required bool isDark,
    required Color surfaceColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: textColor, size: 22),
      ),
    );
  }

  // ════════════════════════════════════════
  // HELPER: Time-based greeting
  // ════════════════════════════════════════
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 🌅';
    if (hour < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  // ════════════════════════════════════════
  // HELPER: Smooth page route
  // ════════════════════════════════════════
  Route _smoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
