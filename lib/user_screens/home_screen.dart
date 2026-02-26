import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../services/preferences_service.dart';
import '../services/draft_order_service.dart';
import '../services/draft_sync_service.dart';
import '../services/verification_service.dart';

import 'upload_prescription_screen.dart';
import 'profile/profile_screen.dart';
import 'explore_products_screen.dart';
import 'verification/verify_account_screen.dart';

// ============================================================
// HOME SCREEN — Telegram-inspired modern pharmacy UI
// + Draft sync prompt after verification (background upload)
// + "Not verified" popup with 24h snooze
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

  // ── Draft sync overlay state ──
  bool _syncInProgress = false;
  DraftSyncProgress? _syncProgress;

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

    // ── Post-frame checks: verification popup + draft sync prompt ──
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowNotVerifiedPopup();
      _checkDraftSyncPrompt();
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

  // ============================================================
  // "Not Verified" popup logic (24h snooze)
  // ============================================================
  Future<void> _maybeShowNotVerifiedPopup() async {
    // If snoozed and snooze is still active, skip
    final snoozeUntil = PreferencesService.getVerifyPopupSnoozeUntil();
    if (snoozeUntil != null && snoozeUntil.isAfter(DateTime.now())) {
      return;
    }

    final status = await VerificationService.getMyVerificationStatus();
    if (!mounted) return;

    // Only show if NOT approved
    if (status == 'approved') return;

    _showNotVerifiedPopup(status);
  }

  void _showNotVerifiedPopup(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    String title;
    String subtitle;

    if (status == 'pending') {
      title = 'Verification pending';
      subtitle =
          "We're reviewing your account. Meanwhile you can create demo orders.";
    } else {
      title = 'Verify to place orders';
      subtitle =
          'Your demo orders are saved on this device. Verify to place them for real.';
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Not verified',
      barrierColor: Colors.black.withOpacity(isDark ? 0.60 : 0.40),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => Center(
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.88,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Playful "reward" icon ──
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_open_rounded,
                        size: 32,
                        color: Colors.teal.shade500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Psychological perk bullets ──
                    _perkRow(
                      'Unlock real orders',
                      Icons.receipt_long_rounded,
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _perkRow(
                      'Faster processing',
                      Icons.flash_on_rounded,
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _perkRow(
                      'Trusted pharmacies',
                      Icons.verified_rounded,
                      isDark,
                    ),

                    const SizedBox(height: 16),

                    // ── Verify now button ──
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await PreferencesService.clearVerifyPopupSnooze();
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            _smoothRoute(const VerifyAccountScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Verify now',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Not now (snooze 24h) button ──
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () async {
                          await PreferencesService.snoozeVerifyPopupFor24h();
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          'Not now',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  Widget _perkRow(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Draft sync prompt logic (runs once after verification)
  // ============================================================
  Future<void> _checkDraftSyncPrompt() async {
    if (PreferencesService.getDraftPromptShown()) return;

    final approved = await VerificationService.isApproved();
    if (!approved) return;

    final drafts = await DraftOrderService.getDraftOrders();
    if (drafts.isEmpty) return;

    if (!mounted) return;

    await PreferencesService.setDraftPromptShown(true);

    _showDraftDecisionPopup(drafts.length);
  }

  void _showDraftDecisionPopup(int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Draft decision',
      barrierColor: Colors.black.withOpacity(isDark ? 0.65 : 0.45),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.88,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Colors.green.shade500,
                        size: 38,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "You're verified!",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have $count demo order(s) saved on this device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Place all drafts ──
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _startBackgroundDraftUpload();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Place all demo orders',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Delete all drafts ──
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () async {
                            await DraftSyncService.deleteAllDrafts();
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All demo orders deleted.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            'Delete all demo orders',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  // ============================================================
  // Background draft upload
  // ============================================================
  Future<void> _startBackgroundDraftUpload() async {
    if (_syncInProgress) return;

    setState(() {
      _syncInProgress = true;
      _syncProgress = const DraftSyncProgress(
        total: 1,
        done: 0,
        message: 'Starting...',
      );
    });

    final result = await DraftSyncService.uploadAllDrafts(
      onProgress: (p) {
        if (!mounted) return;
        setState(() => _syncProgress = p);
      },
    );

    if (!mounted) return;

    setState(() {
      _syncInProgress = false;
      _syncProgress = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================
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
          child: Stack(
            children: [
              // ── Main scroll content ──
              CustomScrollView(
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

                          // ── EXPLORE BUTTON ──
                          _buildExploreButton(isDark),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ════════════════════════════════════════
                  // PRODUCTS GRID
                  // ════════════════════════════════════════
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.82,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
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

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),

              // ════════════════════════════════════════
              // SYNC PROGRESS — Tiny top pill overlay
              // ════════════════════════════════════════
              if (_syncInProgress && _syncProgress != null)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 10,
                  child: SafeArea(child: _buildSyncOverlayTiny(isDark)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // SYNC OVERLAY — Tiny rounded pill at top
  // ════════════════════════════════════════
  Widget _buildSyncOverlayTiny(bool isDark) {
    final p = _syncProgress!;
    final progressValue = (p.total > 0)
        ? (p.done / p.total).clamp(0.0, 1.0)
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  value: progressValue,
                  color: Colors.teal.shade400,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  p.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${p.done}/${p.total}',
                style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.55,
                  ),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
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
  // EXPLORE BUTTON
  // ════════════════════════════════════════
  Widget _buildExploreButton(bool isDark) {
    return AnimatedBuilder(
      animation: _exploreGlow,
      builder: (context, child) {
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
