import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'payment_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPage = 1; // 0 = Payment, 1 = Home

  // Tutorial state
  bool _showTutorial = false;
  bool _dontShowAgain = false;
  // ignore: unused_field
  int _orderCount = 0;

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final dontShow = prefs.getBool('swipe_tutorial_dismissed') ?? false;
    final orderCount = prefs.getInt('user_order_count') ?? 0;

    setState(() {
      _orderCount = orderCount;
      // Show tutorial if not dismissed AND order count <= 2
      _showTutorial = !dontShow && orderCount <= 2;
    });
  }

  Future<void> _dismissTutorial({bool permanently = false}) async {
    if (permanently) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('swipe_tutorial_dismissed', true);
    }
    setState(() {
      _showTutorial = false;
      _dontShowAgain = false;
    });
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page View for swipe navigation
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: const [
              PaymentScreen(), // Page 0 (Left)
              HomeScreen(), // Page 1 (Center/Default)
            ],
          ),

          // Swipe Indicator Arrow (on Home screen)
          if (_currentPage == 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 0,
              child: _buildSwipeHintArrow(context),
            ),

          // Tutorial Overlay
          if (_showTutorial && _currentPage == 1)
            _buildTutorialOverlay(context),
        ],
      ),
    );
  }

  Widget _buildSwipeHintArrow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(seconds: 2),
        builder: (context, value, child) {
          // Loop animation
          final offset = (value <= 0.5 ? value * 2 : 2 - value * 2) * 8;

          return Transform.translate(
            offset: Offset(offset, 0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.teal.shade800.withOpacity(0.9)
                    : Colors.teal.shade600,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.shade400.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.payments_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        },
        onEnd: () {
          // Restart animation
          setState(() {});
        },
      ),
    );
  }

  Widget _buildTutorialOverlay(BuildContext context) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _dismissTutorial(),
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          _dismissTutorial();
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Swipe Animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1500),
                        builder: (context, value, child) {
                          final slideValue = (value <= 0.5
                              ? value * 2
                              : 2 - value * 2);
                          return Transform.translate(
                            offset: Offset(slideValue * 40, 0),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.teal.shade500,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.teal.withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.swipe_right_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          );
                        },
                        onEnd: () => setState(() {}),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Swipe Right for Payments',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Access your payment details and delivery codes by swiping from left to right',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Don't show again checkbox
                      GestureDetector(
                        onTap: () {
                          setState(() => _dontShowAgain = !_dontShowAgain);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _dontShowAgain
                                    ? Colors.teal.shade500
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _dontShowAgain
                                      ? Colors.teal.shade500
                                      : Colors.white.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: _dontShowAgain
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Don\'t show this again',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Got it button
                      SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () =>
                              _dismissTutorial(permanently: _dontShowAgain),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade500,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Got it!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tap anywhere hint
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Tap anywhere to dismiss',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
