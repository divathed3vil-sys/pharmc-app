import 'dart:convert';
import 'dart:typed_data';
import 'package:hive/hive.dart';

class DraftAddress {
  final String label;
  final String addressLine;
  final double latitude;
  final double longitude;

  DraftAddress({
    required this.label,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'address_line': addressLine,
    'latitude': latitude,
    'longitude': longitude,
  };

  static DraftAddress fromJson(Map<String, dynamic> json) => DraftAddress(
    label: (json['label'] ?? 'Home').toString(),
    addressLine: (json['address_line'] ?? '').toString(),
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );
}

class DraftImage {
  final String name;
  final int size;
  final Uint8List bytes;

  DraftImage({required this.name, required this.size, required this.bytes});

  Map<String, dynamic> toJson() => {
    'name': name,
    'size': size,
    'bytes_b64': base64Encode(bytes),
  };

  static DraftImage fromJson(Map<String, dynamic> json) => DraftImage(
    name: (json['name'] ?? 'image').toString(),
    size: (json['size'] as num).toInt(),
    bytes: base64Decode((json['bytes_b64'] ?? '').toString()),
  );
}

class DraftOrder {
  final String id; // local id
  final String orderName;
  final String pharmacyName;
  final String notes;
  final String paymentMethod;
  final DraftAddress address;
  final List<DraftImage> images;
  final DateTime createdAt;

  DraftOrder({
    required this.id,
    required this.orderName,
    required this.pharmacyName,
    required this.notes,
    required this.paymentMethod,
    required this.address,
    required this.images,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_name': orderName,
    'pharmacy_name': pharmacyName,
    'notes': notes,
    'payment_method': paymentMethod,
    'address': address.toJson(),
    'images': images.map((e) => e.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
  };

  static DraftOrder fromJson(Map<String, dynamic> json) => DraftOrder(
    id: (json['id'] ?? '').toString(),
    orderName: (json['order_name'] ?? '').toString(),
    pharmacyName: (json['pharmacy_name'] ?? 'Any Pharmacy').toString(),
    notes: (json['notes'] ?? '').toString(),
    paymentMethod: (json['payment_method'] ?? 'cash').toString(),
    address: DraftAddress.fromJson(Map<String, dynamic>.from(json['address'])),
    images: (json['images'] as List<dynamic>? ?? [])
        .map((e) => DraftImage.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    createdAt:
        DateTime.tryParse((json['created_at'] ?? '').toString()) ??
        DateTime.now(),
  );
}

class DraftOrderService {
  static const _boxName = 'draft_box';

  static const _keyDraftAddress = 'draft_address'; // single
  static const _keyDraftOrders = 'draft_orders'; // list

  static Future<Box> _box() async => Hive.openBox(_boxName);

  // ---------- Address (single) ----------
  static Future<void> saveDraftAddress(DraftAddress address) async {
    final box = await _box();
    await box.put(_keyDraftAddress, address.toJson());
  }

  static Future<DraftAddress?> getDraftAddress() async {
    final box = await _box();
    final raw = box.get(_keyDraftAddress);
    if (raw == null) return null;
    return DraftAddress.fromJson(Map<String, dynamic>.from(raw));
  }

  static Future<void> clearDraftAddress() async {
    final box = await _box();
    await box.delete(_keyDraftAddress);
  }

  // ---------- Orders (list) ----------
  static Future<List<DraftOrder>> getDraftOrders() async {
    final box = await _box();
    final rawList = box.get(_keyDraftOrders) as List<dynamic>?;
    if (rawList == null) return [];
    return rawList
        .map((e) => DraftOrder.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> addDraftOrder(DraftOrder order) async {
    final box = await _box();
    final orders = await getDraftOrders();
    orders.insert(0, order); // newest first
    await box.put(_keyDraftOrders, orders.map((e) => e.toJson()).toList());
  }

  static Future<void> deleteDraftOrder(String id) async {
    final box = await _box();
    final orders = await getDraftOrders();
    orders.removeWhere((o) => o.id == id);
    await box.put(_keyDraftOrders, orders.map((e) => e.toJson()).toList());
  }

  static Future<void> clearAllDrafts() async {
    final box = await _box();
    await box.delete(_keyDraftAddress);
    await box.delete(_keyDraftOrders);
  }

  static Future<Map<String, dynamic>?> getDraftAddressAsMap() async {
    final addr = await getDraftAddress();
    if (addr == null) return null;
    return {
      'id': 'local_address', // fake id for UI consistency
      'label': addr.label,
      'address_line': addr.addressLine,
      'city': 'Local',
      'latitude': addr.latitude,
      'longitude': addr.longitude,
      'is_default': true,
      'is_local': true,
    };
  }
}
