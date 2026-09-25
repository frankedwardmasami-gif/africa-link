import 'supabase_service.dart';
import 'connection_service.dart';
import '../repositories/messaging_repository.dart';
import '../repositories/social_repository.dart';

/// Single interaction facade used by higher-level UI flows.
/// It does not replace the focused repositories/services; it coordinates them.
class PlatformService {
  final db = SupabaseService.client;
  final connections = ConnectionService();
  final messaging = MessagingRepository();
  final social = SocialRepository();

  String get uid => db.auth.currentUser!.id;

  Future<void> likePost(String postId, bool liked) => social.toggleLike(postId, liked);
  Future<void> commentOnPost(String postId, String body) => social.addComment(postId, body);
  Future<String> messageUser(String userId) => messaging.startConversation(userId);
  Future<String> requestConnection(String userId) => connections.connect(userId);

  Future<void> markNotificationRead(String id) async {
    await db.from('notifications').update({'read': true}).eq('id', id).eq('user_id', uid);
  }

  Future<Map<String,dynamic>?> myProfile() => db.from('profiles').select().eq('id', uid).maybeSingle();
}
