import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfigService {
  static final _client = Supabase.instance.client;

  static Map<String, String> _cache = {
    'support_email': 'example@gmail.com',
    'project_by': 'Harish',
    'developer_by': 'Diva',
  };

  static Future<void> refresh() async {
    try {
      final rows = await _client.from('app_config').select('key,value');
      final map = <String, String>{};
      for (final r in rows) {
        map[(r['key'] ?? '').toString()] = (r['value'] ?? '').toString();
      }
      if (map.isNotEmpty) _cache = {..._cache, ...map};
    } catch (_) {}
  }

  static String getSupportEmail() =>
      _cache['support_email'] ?? 'example@gmail.com';
  static String getProjectByName() => _cache['project_by'] ?? 'Harish';
  static String getDeveloperName() => _cache['developer_by'] ?? 'Diva';
}
