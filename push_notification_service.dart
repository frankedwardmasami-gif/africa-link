import 'dart:io';
import 'supabase_service.dart';

class PushNotificationService {
  Future<void> registerDevice(String token) async {
    final platform = Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'web');
    await SupabaseService.client.rpc('register_push_device', params: {
      'p_token': token,
      'p_platform': platform,
    });
  }
}
