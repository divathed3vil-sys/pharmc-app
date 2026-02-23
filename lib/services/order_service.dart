import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  static final _client = Supabase.instance.client;

  // ============ CREATE ORDER ============
  static Future<OrderResult> createOrder({
    required String pharmacyName,
    String? pharmacyAddress,
    String? notes,
    String? deliveryAddressId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return OrderResult(success: false, message: 'Not logged in.');
      }

      final data = await _client
          .from('orders')
          .insert({
            'user_id': userId,
            'pharmacy_name': pharmacyName,
            'pharmacy_address': pharmacyAddress,
            'notes': notes,
            'delivery_address_id': deliveryAddressId,
            'status': 'pending_review',
          })
          .select()
          .single();

      // Also insert initial status history
      await _client.from('order_status_history').insert({
        'order_id': data['id'],
        'status': 'pending_review',
        'changed_by': userId,
        'note': 'Order placed by customer',
      });

      return OrderResult(
        success: true,
        message: 'Order created!',
        orderId: data['id'],
      );
    } catch (e) {
      return OrderResult(success: false, message: 'Failed to create order.');
    }
  }

  // ============ UPLOAD PRESCRIPTION IMAGE ============
  static Future<OrderResult> uploadPrescriptionImage({
    required String orderId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return OrderResult(success: false, message: 'Not logged in.');
      }

      // Upload to storage: prescriptions/userId/orderId/filename
      final storagePath = '$userId/$orderId/$fileName';

      await _client.storage
          .from('prescriptions')
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get the URL
      final imageUrl = _client.storage
          .from('prescriptions')
          .getPublicUrl(storagePath);

      // Save reference in prescription_images table
      await _client.from('prescription_images').insert({
        'order_id': orderId,
        'image_url': imageUrl,
        'file_name': fileName,
      });

      return OrderResult(success: true, message: 'Image uploaded!');
    } catch (e) {
      return OrderResult(success: false, message: 'Failed to upload image.');
    }
  }

  // ============ GET USER ORDERS ============
  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final data = await _client
          .from('orders')
          .select('*, prescription_images(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  // ============ GET ACTIVE ORDERS ============
  static Future<List<Map<String, dynamic>>> getActiveOrders() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final data = await _client
          .from('orders')
          .select('*, prescription_images(*)')
          .eq('user_id', userId)
          .not('status', 'in', '("delivered","cancelled")')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  // ============ GET PAST ORDERS ============
  static Future<List<Map<String, dynamic>>> getPastOrders() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final data = await _client
          .from('orders')
          .select('*, prescription_images(*)')
          .eq('user_id', userId)
          .inFilter('status', ['delivered', 'cancelled'])
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  // ============ GET ORDER STATUS HISTORY ============
  static Future<List<Map<String, dynamic>>> getOrderHistory(
    String orderId,
  ) async {
    try {
      final data = await _client
          .from('order_status_history')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  // ============ CANCEL ORDER ============
  static Future<OrderResult> cancelOrder(String orderId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return OrderResult(success: false, message: 'Not logged in.');
      }

      await _client
          .from('orders')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('user_id', userId);

      await _client.from('order_status_history').insert({
        'order_id': orderId,
        'status': 'cancelled',
        'changed_by': userId,
        'note': 'Cancelled by customer',
      });

      return OrderResult(success: true, message: 'Order cancelled.');
    } catch (e) {
      return OrderResult(success: false, message: 'Failed to cancel order.');
    }
  }

  // ============ STATUS HELPERS ============
  static String getStatusLabel(String status) {
    switch (status) {
      case 'pending_review':
        return 'Pending Review';
      case 'pharmacist_verified':
        return 'Pharmacist Verified';
      case 'price_sent':
        return 'Price Sent';
      case 'price_accepted':
        return 'Price Accepted';
      case 'price_rejected':
        return 'Price Rejected';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static List<String> getAllSteps() {
    return [
      'pending_review',
      'pharmacist_verified',
      'price_accepted',
      'preparing',
      'out_for_delivery',
      'delivered',
    ];
  }
}

class OrderResult {
  final bool success;
  final String message;
  final String? orderId;

  OrderResult({required this.success, required this.message, this.orderId});
}
