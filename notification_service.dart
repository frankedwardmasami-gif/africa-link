import 'supabase_service.dart';
class NotificationService {
  Stream<List<Map<String,dynamic>>> stream(String userId) =>
    SupabaseService.client.from('notifications').stream(primaryKey:['id'])
      .eq('user_id', userId).order('created_at',ascending:false);
  Future<void> markRead(String id) async {
    final uid=SupabaseService.client.auth.currentUser?.id;
    if(uid==null)return;
    await SupabaseService.client.from('notifications').update({'read':true}).eq('id',id).eq('user_id',uid);
  }
}
