class ProfileModel {
  final String id;
  final String fullName;
  final String username;
  final String? photoUrl;
  final String? email;
  final String? phone;
  final String? citizenship;
  final String? currentCountry;
  final List<String> languages;
  final List<String> skills;
  final List<String> interests;
  final String? bio;
  final String verificationStatus;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.photoUrl,
    this.email,
    this.phone,
    this.citizenship,
    this.currentCountry,
    this.languages = const [],
    this.skills = const [],
    this.interests = const [],
    this.bio,
    this.verificationStatus = 'unverified',
  });

  factory ProfileModel.fromMap(Map<String, dynamic> m) => ProfileModel(
    id: m['id'] as String,
    fullName: (m['full_name'] ?? '') as String,
    username: (m['username'] ?? '') as String,
    photoUrl: m['photo_url'] as String?,
    email: m['email'] as String?,
    phone: m['phone'] as String?,
    citizenship: m['african_citizenship'] as String?,
    currentCountry: m['current_country'] as String?,
    languages: List<String>.from(m['languages'] ?? const []),
    skills: List<String>.from(m['skills'] ?? const []),
    interests: List<String>.from(m['interests'] ?? const []),
    bio: m['bio'] as String?,
    verificationStatus: (m['verification_status'] ?? 'unverified') as String,
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'full_name': fullName, 'username': username,
    'photo_url': photoUrl, 'email': email, 'phone': phone,
    'african_citizenship': citizenship, 'current_country': currentCountry,
    'languages': languages, 'skills': skills, 'interests': interests,
    'bio': bio, 'verification_status': verificationStatus,
  };
}
