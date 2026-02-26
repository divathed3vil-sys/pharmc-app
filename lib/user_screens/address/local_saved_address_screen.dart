import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/draft_order_service.dart';
import 'local_add_address_screen.dart';

class LocalSavedAddressScreen extends StatefulWidget {
  final bool selectMode;
  const LocalSavedAddressScreen({super.key, this.selectMode = false});

  @override
  State<LocalSavedAddressScreen> createState() =>
      _LocalSavedAddressScreenState();
}

class _LocalSavedAddressScreenState extends State<LocalSavedAddressScreen> {
  Map<String, dynamic>? _localAddress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _localAddress = await DraftOrderService.getDraftAddressAsMap();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addOrEdit() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocalAddAddressScreen()),
    );
    if (ok == true) _load();
  }

  Future<void> _delete() async {
    await DraftOrderService.clearDraftAddress();
    await _load();
  }

  void _select() {
    if (_localAddress == null) return;
    Navigator.pop(context, _localAddress);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final text = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.selectMode ? 'Select Address' : 'Draft Address',
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _addOrEdit,
            icon: Icon(Icons.add_rounded, color: Colors.teal.shade400),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Colors.teal.shade600,
                    strokeWidth: 2.4,
                  ),
                )
              : _localAddress == null
              ? _empty(isDark, sub)
              : _glassCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localAddress!['label'] ?? 'Home',
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _localAddress!['address_line'] ?? '',
                        style: TextStyle(color: sub, height: 1.4),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: _delete,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.14)
                                        : Colors.black.withOpacity(0.08),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: widget.selectMode
                                    ? _select
                                    : _addOrEdit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade600,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  widget.selectMode
                                      ? 'Use this address'
                                      : 'Edit',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _empty(bool isDark, Color sub) {
    return _glassCard(
      isDark: isDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 56, color: sub),
          const SizedBox(height: 10),
          Text(
            'No draft address',
            style: TextStyle(color: sub, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _addOrEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Add Address',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
