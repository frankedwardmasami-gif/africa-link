import 'supabase_service.dart';

class AdvancedSocialService {
  final db = SupabaseService.client;
  String get uid => db.auth.currentUser!.id;

  Future<String> requestConnection(String otherId) async {
    final result = await db.rpc('request_connection', params: {'p_other_user_id': otherId});
    return '$result';
  }

  Future<List<Map<String,dynamic>>> connections() async {
    final rows = await db.from('user_connections').select().eq('status','accepted').or('requester_id.eq.$uid,addressee_id.eq.$uid').order('updated_at', ascending: false);
    final ids = rows.map<String>((r) => r['requester_id'] == uid ? r['addressee_id'] as String : r['requester_id'] as String).toList();
    if (ids.isEmpty) return [];
    final profiles = await db.from('profiles').select('id,full_name,username,photo_url,verification_status').inFilter('id', ids);
    return profiles.cast<Map<String,dynamic>>();
  }

  Future<List<Map<String,dynamic>>> incomingRequests() async {
    final rows = await db.from('user_connections').select('requester_id,status,created_at').eq('addressee_id', uid).eq('status','pending').order('created_at', ascending: false);
    final ids = rows.map<String>((r) => r['requester_id'] as String).toList();
    if (ids.isEmpty) return [];
    final profiles = await db.from('profiles').select('id,full_name,username,photo_url').inFilter('id', ids);
    return profiles.cast<Map<String,dynamic>>();
  }

  Future<String> respond(String requesterId, bool accept) async =>
      '${await db.rpc('respond_connection', params: {'p_requester_id': requesterId, 'p_accept': accept})}';

  Future<void> removeConnection(String otherId) async {
    await db.from('user_connections').delete().or('and(requester_id.eq.$uid,addressee_id.eq.$otherId),and(requester_id.eq.$otherId,addressee_id.eq.$uid)');
  }

  Future<List<Map<String,dynamic>>> comments(String postId) async => (await db.from('post_comments').select().eq('post_id', postId).order('created_at', ascending: true)).cast<Map<String,dynamic>>();
  Future<void> addComment(String postId, String body) async => db.from('comments').insert({'post_id':postId,'author_id':uid,'body':body.trim()});
  Future<void> deleteComment(String id) async => db.from('comments').delete().eq('id', id).eq('author_id', uid);

  Future<List<Map<String,dynamic>>> eventMembers(String eventId) async => (await db.from('event_registrations').select('user_id,registered_at,profiles(full_name,username,photo_url)').eq('event_id', eventId).order('registered_at')).cast<Map<String,dynamic>>();
  Future<List<Map<String,dynamic>>> projectMembers(String projectId) async => (await db.from('project_members').select('user_id,joined_at,profiles(full_name,username,photo_url)').eq('project_id', projectId).order('joined_at')).cast<Map<String,dynamic>>();
  Future<List<Map<String,dynamic>>> marketplace(String businessId) async => (await db.from('marketplace_listings').select('id,title,description,price,currency,created_at').eq('business_id', businessId).order('created_at', ascending:false)).cast<Map<String,dynamic>>();
}
