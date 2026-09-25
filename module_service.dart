import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ModuleService {
  final SupabaseClient db = SupabaseService.client;
  String get uid => db.auth.currentUser!.id;

  Future<List<Map<String,dynamic>>> list(String table) async =>
      await db.from(table).select().order('created_at', ascending: false);
  Future<Map<String,dynamic>> detail(String table, String id) async =>
      await db.from(table).select().eq('id', id).single();

  Future<void> toggleCommunity(String id, bool joined) async {
    if (joined) {
      await db.from('community_members').delete().match({'community_id': id, 'user_id': uid});
    } else {
      await db.from('community_members').upsert({'community_id': id, 'user_id': uid});
    }
  }
  Future<bool> isMember(String table, String column, String id) async =>
      (await db.from(table).select('id').eq(column, id).eq('user_id', uid).maybeSingle()) != null;
  Future<List<Map<String,dynamic>>> members(String communityId) async =>
      await db.from('community_members').select('user_id, profiles(full_name,username,photo_url)').eq('community_id', communityId);
  Future<void> addCommunityPost(String communityId, String body) async =>
      await db.from('community_posts').insert({'community_id': communityId, 'author_id': uid, 'body': body.trim()});
  Future<List<Map<String,dynamic>>> communityPosts(String id) async =>
      await db.from('community_posts').select('*, profiles(full_name,username)').eq('community_id', id).order('created_at', ascending: false);

  Future<void> toggleEvent(String id, bool registered) async {
    if (registered) {
      await db.from('event_registrations').delete().match({'event_id': id, 'user_id': uid});
    } else {
      await db.from('event_registrations').upsert({'event_id': id, 'user_id': uid});
    }
  }
  Future<void> enrollCourse(String id) async => await db.from('course_enrollments').upsert({'course_id': id, 'user_id': uid});
  Future<bool> isEnrolled(String id) async => await isMember('course_enrollments', 'course_id', id);
  Future<List<Map<String,dynamic>>> lessons(String courseId) async => await db.from('lessons').select().eq('course_id', courseId).order('position');
  Future<bool> lessonCompleted(String lessonId) async => (await db.from('lesson_progress').select('completed').eq('lesson_id', lessonId).eq('user_id', uid).maybeSingle())?['completed'] == true;
  Future<void> setLessonProgress(String lessonId, bool completed) async => await db.from('lesson_progress').upsert({'lesson_id': lessonId, 'user_id': uid, 'completed': completed, 'updated_at': DateTime.now().toIso8601String()});
  Future<List<Map<String,dynamic>>> quizzes(String courseId) async => await db.from('quizzes').select().eq('course_id', courseId);
  Future<void> recordQuizAttempt(String quizId, num score) async => await db.from('quiz_attempts').insert({'quiz_id': quizId, 'user_id': uid, 'score': score});

  Future<void> applyFunding(String id, String statement) async => await db.from('funding_applications').upsert({'opportunity_id': id, 'user_id': uid, 'statement': statement.trim(), 'status': 'submitted'});
  Future<Map<String,dynamic>?> myFundingApplication(String id) async => await db.from('funding_applications').select().eq('opportunity_id', id).eq('user_id', uid).maybeSingle();

  Future<void> joinProject(String id, bool joined) async {
    if (joined) await db.from('project_members').delete().match({'project_id': id, 'user_id': uid});
    else await db.from('project_members').upsert({'project_id': id, 'user_id': uid});
  }
  Future<List<Map<String,dynamic>>> projectSkills(String id) async => await db.from('project_skills').select().eq('project_id', id);

  Future<void> createInquiry(String businessId, String message) async => await db.from('business_inquiries').insert({'business_id': businessId, 'user_id': uid, 'message': message.trim()});
  Future<void> createPartnershipRequest(String businessId, String message) async => await db.from('business_partnerships').insert({'business_id': businessId, 'user_id': uid, 'message': message.trim()});
  Future<List<Map<String,dynamic>>> listings(String businessId) async => await db.from('marketplace_listings').select().eq('business_id', businessId).order('created_at', ascending: false);

  Future<String> getOrCreateCommunityConversation(String communityId) async {
    final row = await db.rpc('get_or_create_community_conversation', params: {'p_community_id': communityId});
    return row as String;
  }
}
