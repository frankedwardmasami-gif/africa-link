class MessageModel {
  final String id, conversationId, senderId, body;
  final DateTime createdAt;
  const MessageModel({required this.id, required this.conversationId,
    required this.senderId, required this.body, required this.createdAt});
  factory MessageModel.fromMap(Map<String,dynamic> m) => MessageModel(
    id:m['id'], conversationId:m['conversation_id'], senderId:m['sender_id'],
    body:m['body'] ?? '', createdAt:DateTime.parse(m['created_at']));
}
