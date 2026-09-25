import '../models/post_model.dart';
import '../services/supabase_service.dart';

class SocialRepository {
  final _db = SupabaseService.client;

  Stream<List<PostModel>> feedStream() {
    return _db.from('feed_posts').stream(primaryKey: ['id'])
      .order('created_at', ascending: false).limit(50)
      .map((rows) => rows.map((r) => PostModel.fromMap(r)).toList());
  }

  Future<void> createPost(String body) async {
    await _db.from('posts').insert({'body': body.trim(), 'author_id': _db.auth.currentUser!.id});
  }
  Future<void> toggleLike(String postId, bool currentlyLiked) async {
    if (currentlyLiked) {
      await _db.from('post_likes').delete().match({'post_id': postId, 'user_id': _db.auth.currentUser!.id});
    } else {
      await _db.from('post_likes').insert({'post_id': postId, 'user_id': _db.auth.currentUser!.id});
    }
  }
  Future<void> addComment(String postId, String body) async {
    await _db.from('comments').insert({'post_id': postId, 'author_id': _db.auth.currentUser!.id, 'body': body.trim()});
  }
}
