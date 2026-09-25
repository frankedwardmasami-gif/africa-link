import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    if (!AppConfig.configured) return;
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
}
