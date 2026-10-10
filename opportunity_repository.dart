import '../services/supabase_service.dart';
class OpportunityRepository {
  final _db = SupabaseService.client;
  Future<List<Map<String,dynamic>>> list() async =>
      await _db.from('opportunities').select().order('deadline');
  Future<void> save(String id) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw StateError('Not authenticated');
    await _db.from('opportunity_saves').upsert({
      'opportunity_id': id,
      'user_id': uid,
    });
  }
}
