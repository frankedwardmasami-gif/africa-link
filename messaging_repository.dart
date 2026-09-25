import '../models/message_model.dart';
import '../services/supabase_service.dart';
class MessagingRepository{
 final _db=SupabaseService.client;
 Stream<List<MessageModel>> messages(String conversationId)=>_db.from('messages').stream(primaryKey:['id']).eq('conversation_id',conversationId).order('created_at').map((rows)=>rows.map(MessageModel.fromMap).toList());
 Future<void> send(String conversationId,String body)async{final uid=_db.auth.currentUser!.id;await _db.from('messages').insert({'conversation_id':conversationId,'sender_id':uid,'body':body.trim()});}
 Future<String> startConversation(String otherUserId)async{final row=await _db.rpc('get_or_create_direct_conversation',params:{'other_user_id':otherUserId});return row as String;}
}
