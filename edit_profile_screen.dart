import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController name;
  late final TextEditingController user;
  late final TextEditingController bio;
  late final TextEditingController country;
  late final TextEditingController skills;
  late final TextEditingController interests;
  late final TextEditingController languages;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    name = TextEditingController(text: '${p['full_name'] ?? ''}');
    user = TextEditingController(text: '${p['username'] ?? ''}');
    bio = TextEditingController(text: '${p['bio'] ?? ''}');
    country = TextEditingController(text: '${p['current_country'] ?? ''}');
    skills = TextEditingController(text: List<String>.from(p['skills'] ?? const []).join(', '));
    interests = TextEditingController(text: List<String>.from(p['interests'] ?? const []).join(', '));
    languages = TextEditingController(text: List<String>.from(p['languages'] ?? const []).join(', '));
  }

  @override
  void dispose() {
    name.dispose();
    user.dispose();
    bio.dispose();
    country.dispose();
    skills.dispose();
    interests.dispose();
    languages.dispose();
    super.dispose();
  }

  List<String> split(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  Future<void> save() async {
    if (name.text.trim().isEmpty || user.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name and username are required.')),
      );
      return;
    }
    setState(() => busy = true);
    try {
      final id = SupabaseService.client.auth.currentUser!.id;
      await SupabaseService.client.from('profiles').update({
        'full_name': name.text.trim(),
        'username': user.text.trim(),
        'bio': bio.text.trim(),
        'current_country': country.text.trim(),
        'skills': split(skills.text),
        'interests': split(interests.text),
        'languages': split(languages.text),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(String label, TextEditingController controller, {int max = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: max,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          field('Full name', name),
          field('Username', user),
          field('Current country', country),
          field('Bio', bio, max: 4),
          field('Languages', languages),
          field('Skills', skills),
          field('Interests', interests),
          FilledButton.icon(
            onPressed: busy ? null : save,
            icon: const Icon(Icons.save),
            label: Text(busy ? 'Saving...' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}
