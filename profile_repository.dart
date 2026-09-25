import '../models/profile_model.dart';
import '../services/supabase_service.dart';

class ProfileRepository {
  final _db = SupabaseService.client;
  Future<ProfileModel?> getMyProfile(String id) async {
    final row = await _db.from('profiles').select().eq('id', id).maybeSingle();
    return row == null ? null : ProfileModel.fromMap(row);
  }
  Future<void> upsert(ProfileModel p) async {
    await _db.from('profiles').upsert(p.toMap());
  }
}
