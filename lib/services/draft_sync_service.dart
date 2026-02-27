import 'package:supabase_flutter/supabase_flutter.dart';
import 'draft_order_service.dart';

class DraftSyncProgress {
  final int total;
  final int done;
  final String message;
  const DraftSyncProgress({
    required this.total,
    required this.done,
    required this.message,
  });
}

class DraftSyncResult {
  final bool success;
  final String message;
  final int uploaded;
  final int failed;

  const DraftSyncResult({
    required this.success,
    required this.message,
    required this.uploaded,
    required this.failed,
  });
}

class DraftSyncService {
  static final _client = Supabase.instance.client;

  /// Upload all draft orders as real orders.
  /// - Creates ONE DB address and attaches it to all orders.
  static Future<DraftSyncResult> uploadAllDrafts({
    void Function(DraftSyncProgress progress)? onProgress,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const DraftSyncResult(
        success: false,
        message: 'Not logged in.',
        uploaded: 0,
        failed: 0,
      );
    }

    final drafts = await DraftOrderService.getDraftOrders();
    if (drafts.isEmpty) {
      return const DraftSyncResult(
        success: true,
        message: 'No demo orders found.',
        uploaded: 0,
        failed: 0,
      );
    }

    // Must have a local address
    final draftAddr = await DraftOrderService.getDraftAddress();
    if (draftAddr == null) {
      return const DraftSyncResult(
        success: false,
        message: 'No draft address found. Add an address first.',
        uploaded: 0,
        failed: 0,
      );
    }

    // Create ONE DB address
    onProgress?.call(
      DraftSyncProgress(
        total: drafts.length,
        done: 0,
        message: 'Creating your saved address...',
      ),
    );

    final addressRow = await _client
        .from('addresses')
        .insert({
          'user_id': user.id,
          'label': draftAddr.label,
          'address_line': draftAddr.addressLine,
          'city': 'Draft',
          'latitude': draftAddr.latitude, // can be 0,0
          'longitude': draftAddr.longitude,
          'is_default': true,
        })
        .select()
        .single();

    final addressId = addressRow['id'];

    int uploaded = 0;
    int failed = 0;

    // Upload each order
    for (int i = 0; i < drafts.length; i++) {
      final d = drafts[i];

      try {
        onProgress?.call(
          DraftSyncProgress(
            total: drafts.length,
            done: i,
            message: 'Placing "${d.orderName}"...',
          ),
        );

        final orderResponse = await _client
            .from('orders')
            .insert({
              'user_id': user.id,
              'order_name': d.orderName,
              'pharmacy_name': d.pharmacyName,
              'pharmacy_address': d.pharmacyName == 'Any Pharmacy'
                  ? 'Auto-assigned'
                  : 'Selected',
              'status': 'order_placed',
              'notes': d.notes,
              'delivery_address_id': addressId,
              'payment_method': d.paymentMethod,
              'total_price': 0.00,
            })
            .select()
            .single();

        final orderId = orderResponse['id'];

        // Upload images
        for (final img in d.images) {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${img.name}';
          final filePath = '${user.id}/$fileName';

          await _client.storage
              .from('prescriptions')
              .uploadBinary(filePath, img.bytes);

          await _client.from('prescription_images').insert({
            'order_id': orderId,
            'image_url': filePath,
            'file_name': img.name,
          });
        }

        await _client.from('order_status_history').insert({
          'order_id': orderId,
          'status': 'order_placed',
          'changed_by': user.id,
          'note': 'Order placed (from demo drafts): ${d.orderName}',
        });

        uploaded++;
      } catch (_) {
        failed++;
      }

      onProgress?.call(
        DraftSyncProgress(
          total: drafts.length,
          done: i + 1,
          message: 'Uploading... (${i + 1}/${drafts.length})',
        ),
      );
    }

    // If all uploaded, clear drafts
    if (failed == 0) {
      await DraftOrderService.clearAllDrafts();
      return DraftSyncResult(
        success: true,
        message: 'All demo orders placed successfully!',
        uploaded: uploaded,
        failed: failed,
      );
    }

    // Partial failure: keep drafts (so user can retry later)
    return DraftSyncResult(
      success: false,
      message:
          'Some demo orders failed to upload. Please try again later. ($uploaded uploaded, $failed failed)',
      uploaded: uploaded,
      failed: failed,
    );
  }

  static Future<void> deleteAllDrafts() async {
    await DraftOrderService.clearAllDrafts();
  }
}
