import 'package:flutter/material.dart';

// ============================================================
// EXPLORE PRODUCTS SCREEN
// Full browsing experience for pharmacy & wellness products
// ============================================================
class ExploreProductsScreen extends StatefulWidget {
  const ExploreProductsScreen({super.key});

  @override
  State<ExploreProductsScreen> createState() => _ExploreProductsScreenState();
}

class _ExploreProductsScreenState extends State<ExploreProductsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  String _selectedCategory = 'All';

  // ── Categories ──
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Supplements', 'icon': Icons.wb_sunny_rounded},
    {'name': 'Skincare', 'icon': Icons.face_retouching_natural_rounded},
    {'name': 'Hygiene', 'icon': Icons.clean_hands_rounded},
    {'name': 'Devices', 'icon': Icons.thermostat_rounded},
    {'name': 'Essentials', 'icon': Icons.medical_services_rounded},
  ];

  // ── All products (replace with Supabase query later) ──
  final List<Map<String, dynamic>> _allProducts = [
    {
      'name': 'Vitamin C 1000mg',
      'category': 'Supplements',
      'price': 850.0,
      'icon': Icons.wb_sunny_rounded,
      'color': Colors.orange,
      'desc': 'Immune system support',
    },
    {
      'name': 'Hand Sanitizer 500ml',
      'category': 'Hygiene',
      'price': 350.0,
      'icon': Icons.clean_hands_rounded,
      'color': Colors.blue,
      'desc': '99.9% germ protection',
    },
    {
      'name': 'Moisturizer SPF30',
      'category': 'Skincare',
      'price': 1200.0,
      'icon': Icons.face_retouching_natural_rounded,
      'color': Colors.pink,
      'desc': 'Daily UV protection',
    },
    {
      'name': 'Digital Thermometer',
      'category': 'Devices',
      'price': 2500.0,
      'icon': Icons.thermostat_rounded,
      'color': Colors.teal,
      'desc': 'Accurate readings in 10s',
    },
    {
      'name': 'First Aid Kit',
      'category': 'Essentials',
      'price': 3200.0,
      'icon': Icons.medical_services_rounded,
      'color': Colors.red,
      'desc': '42-piece emergency kit',
    },
    {
      'name': 'Omega-3 Fish Oil',
      'category': 'Supplements',
      'price': 1800.0,
      'icon': Icons.water_drop_rounded,
      'color': Colors.indigo,
      'desc': 'Heart & brain health',
    },
    {
      'name': 'Aloe Vera Gel',
      'category': 'Skincare',
      'price': 450.0,
      'icon': Icons.eco_rounded,
      'color': Colors.green,
      'desc': 'Soothing & moisturizing',
    },
    {
      'name': 'Blood Pressure Monitor',
      'category': 'Devices',
      'price': 5600.0,
      'icon': Icons.monitor_heart_rounded,
      'color': Colors.red,
      'desc': 'Digital arm monitor',
    },
    {
      'name': 'Antiseptic Wipes',
      'category': 'Hygiene',
      'price': 280.0,
      'icon': Icons.cleaning_services_rounded,
      'color': Colors.cyan,
      'desc': 'Alcohol-free, gentle',
    },
    {
      'name': 'Multivitamin Daily',
      'category': 'Supplements',
      'price': 1500.0,
      'icon': Icons.local_pharmacy_rounded,
      'color': Colors.purple,
      'desc': 'Complete daily nutrition',
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategory == 'All') return _allProducts;
    return _allProducts
        .where((p) => p['category'] == _selectedCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _onCategoryTap(String category) {
    setState(() => _selectedCategory = category);
    _staggerController.reset();
    _staggerController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final backBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: backBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: textColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Explore Products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: subtextColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Search products...',
                      style: TextStyle(fontSize: 15, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Category chips (horizontal scroll OK here,
            //    it's a small strip, won't conflict) ──
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat['name'];

                  return GestureDetector(
                    onTap: () => _onCategoryTap(cat['name'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.teal.shade600
                            : (isDark
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFFF0F0F0)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.teal.shade600
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 16,
                            color: isSelected ? Colors.white : subtextColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Products grid ──
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.75,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  final delay = index * 0.1;
                  final itemAnim = CurvedAnimation(
                    parent: _staggerController,
                    curve: Interval(
                      delay.clamp(0.0, 0.6),
                      (delay + 0.4).clamp(0.0, 1.0),
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
                    child: _buildExploreCard(
                      product,
                      isDark,
                      cardColor,
                      textColor,
                      subtextColor,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreCard(
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
          // ── Icon ──
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
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color.shade400,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),

          // ── Name ──
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

          const SizedBox(height: 2),

          // ── Description ──
          Text(
            product['desc'] as String,
            style: TextStyle(fontSize: 11, color: subtextColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // ── Price row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LKR ${(product['price'] as double).toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.teal.shade600,
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.teal.shade600,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
