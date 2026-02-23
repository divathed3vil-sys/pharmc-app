import 'package:supabase_flutter/supabase_flutter.dart';

class AddressService {
  static final _client = Supabase.instance.client;

  // ============ GET ALL ADDRESSES ============
  static Future<List<Map<String, dynamic>>> getAddresses() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final data = await _client
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  // ============ ADD ADDRESS ============
  static Future<AddressResult> addAddress({
    required String label,
    required String addressLine,
    String? city,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return AddressResult(success: false, message: 'Not logged in.');
      }

      // If setting as default, unset others first
      if (isDefault) {
        await _client
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId);
      }

      await _client.from('addresses').insert({
        'user_id': userId,
        'label': label,
        'address_line': addressLine,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      });

      return AddressResult(success: true, message: 'Address added!');
    } catch (e) {
      return AddressResult(success: false, message: 'Failed to add address.');
    }
  }

  // ============ UPDATE ADDRESS ============
  static Future<AddressResult> updateAddress({
    required String id,
    String? label,
    String? addressLine,
    String? city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return AddressResult(success: false, message: 'Not logged in.');
      }

      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (label != null) updates['label'] = label;
      if (addressLine != null) updates['address_line'] = addressLine;
      if (city != null) updates['city'] = city;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;

      if (isDefault == true) {
        // Unset others first
        await _client
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId);
        updates['is_default'] = true;
      }

      await _client.from('addresses').update(updates).eq('id', id);

      return AddressResult(success: true, message: 'Address updated!');
    } catch (e) {
      return AddressResult(
        success: false,
        message: 'Failed to update address.',
      );
    }
  }

  // ============ DELETE ADDRESS ============
  static Future<AddressResult> deleteAddress(String id) async {
    try {
      await _client.from('addresses').delete().eq('id', id);
      return AddressResult(success: true, message: 'Address deleted.');
    } catch (e) {
      return AddressResult(
        success: false,
        message: 'Failed to delete address.',
      );
    }
  }

  // ============ GET DEFAULT ADDRESS ============
  static Future<Map<String, dynamic>?> getDefaultAddress() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final data = await _client
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      return data;
    } catch (e) {
      return null;
    }
  }

  // ============ SET DEFAULT ============
  static Future<void> setDefault(String id) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', userId);

      await _client.from('addresses').update({'is_default': true}).eq('id', id);
    } catch (_) {}
  }
}

class AddressResult {
  final bool success;
  final String message;

  AddressResult({required this.success, required this.message});
}
