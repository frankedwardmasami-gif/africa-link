import 'supabase_service.dart';

class ConnectionService {
  final db = SupabaseService.client;
  String get uid => db.auth.currentUser!.id;

  Future<String?> statusWith(String otherId) async {
    final a = await db.from('user_connections').select('status,requester_id,addressee_id')
      .or('and(requester_id.eq.$uid,addressee_id.eq.$otherId),and(requester_id.eq.$otherId,addressee_id.eq.$uid)').maybeSingle();
    if (a == null) return null;
    return '${a['status']}|${a['requester_id']}|${a['addressee_id']}';
  }

  Future<String> connect(String otherId) async => '${await db.rpc('request_connection', params: {'p_other_user_id': otherId})}';

  Future<String> respond(String requesterId, bool accept) async =>
      '${await db.rpc('respond_connection', params: {'p_requester_id': requesterId, 'p_accept': accept})}';

  Future<void> remove(String otherId) async => db.from('user_connections').delete()
      .or('and(requester_id.eq.$uid,addressee_id.eq.$otherId),and(requester_id.eq.$otherId,addressee_id.eq.$uid)');

  Future<List<Map<String,dynamic>>> myConnections() async =>
      (await db.from('user_connections').select('requester_id,addressee_id,status').eq('status','accepted')
        .or('requester_id.eq.$uid,addressee_id.eq.$uid')).cast<Map<String,dynamic>>();
}
