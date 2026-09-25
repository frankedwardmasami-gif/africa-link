import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final _client = SupabaseService.client;
  User? get user => _client.auth.currentUser;
  Stream<AuthState> get authState => _client.auth.onAuthStateChange;

  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }
  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }
  Future<void> signOut() => _client.auth.signOut();
  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(email);
}
