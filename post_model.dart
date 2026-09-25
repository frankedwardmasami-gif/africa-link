class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final String body;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool liked;

  const PostModel({
    required this.id, required this.authorId, required this.authorName,
    required this.body, required this.createdAt, this.authorPhoto,
    this.likeCount = 0, this.commentCount = 0, this.liked = false,
  });

  factory PostModel.fromMap(Map<String,dynamic> m) => PostModel(
    id: m['id'], authorId: m['author_id'],
    authorName: m['author_name'] ?? 'AFRICA LINK member',
    authorPhoto: m['author_photo'],
    body: m['body'] ?? '',
    createdAt: DateTime.parse(m['created_at']),
    likeCount: m['like_count'] ?? 0,
    commentCount: m['comment_count'] ?? 0,
    liked: m['liked'] ?? false,
  );
}
