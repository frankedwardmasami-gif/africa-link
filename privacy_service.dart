import 'supabase_service.dart';

class PrivacyService {
  final db = SupabaseService.client;

  Future<Map<String, dynamic>?> getPreferences() async {
    final u = db.auth.currentUser;
    if (u == null) return null;
    return await db.from('user_preferences').select().eq('user_id', u.id).maybeSingle();
  }

  Future<void> save({
    String profileVisibility = 'public',
    bool showOnlineStatus = true,
    bool allowConnectionRequests = true,
    String allowDirectMessages = 'connections',
    String language = 'en',
    bool marketingNotifications = false,
  }) async {
    await db.rpc('save_user_preferences', params: {
      'p_profile_visibility': profileVisibility,
      'p_show_online_status': showOnlineStatus,
      'p_allow_connection_requests': allowConnectionRequests,
      'p_allow_direct_messages': allowDirectMessages,
      'p_language': language,
      'p_marketing_notifications': marketingNotifications,
    });
  }

  Future<void> requestDeletion(String reason) async {
    await db.rpc('request_account_deletion', params: {'p_reason': reason});
  }

  Future<void> cancelDeletion() async {
    await db.rpc('cancel_account_deletion');
  }
}
