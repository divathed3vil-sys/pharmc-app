import 'package:supabase_flutter/supabase_flutter.dart';

class VerificationService {
  static final _client = Supabase.instance.client;

  static Future<String> getMyVerificationStatus() async {
    final user = _client.auth.currentUser;
    if (user == null) return 'unverified';

    final data = await _client
        .from('profiles')
        .select('verification_status')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return 'unverified';
    return (data['verification_status'] ?? 'unverified').toString();
  }

  static Future<bool> isApproved() async {
    return (await getMyVerificationStatus()) == 'approved';
  }
}
