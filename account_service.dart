import 'supabase_service.dart';
class AccountService {
  final db=SupabaseService.client;
  Future<bool> hasProfile() async {
    final u=db.auth.currentUser;
    if(u==null)return false;
    return await db.from('profiles').select('id').eq('id',u.id).maybeSingle()!=null;
  }
  Future<void> signOut()=>db.auth.signOut();
}
