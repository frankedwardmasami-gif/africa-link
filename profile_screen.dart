import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>?> load() async {
    final id = SupabaseService.client.auth.currentUser!.id;
    return SupabaseService.client.from('profiles').select().eq('id', id).maybeSingle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/connections'),
            icon: const Icon(Icons.people_alt_outlined),
          ),
          IconButton(
            onPressed: () => SupabaseService.client.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: load(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Unable to load profile.\n${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              if (mounted) setState(() {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const CircleAvatar(radius: 44, child: Icon(Icons.person, size: 44)),
                const SizedBox(height: 14),
                Text(
                  '${profile['full_name'] ?? ''}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                Text('@${profile['username'] ?? ''}'),
                const SizedBox(height: 14),
                Text('${profile['bio'] ?? ''}'),
                const Divider(height: 30),
                Text('African citizenship: ${profile['african_citizenship'] ?? '-'}'),
                Text('Current country: ${profile['current_country'] ?? '-'}'),
                Text('Languages: ${List<String>.from(profile['languages'] ?? const []).join(', ')}'),
                Text('Skills: ${List<String>.from(profile['skills'] ?? const []).join(', ')}'),
                Text('Interests: ${List<String>.from(profile['interests'] ?? const []).join(', ')}'),
                Text('Verification: ${profile['verification_status'] ?? 'unverified'}'),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
                    );
                    if (changed == true && mounted) setState(() {});
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit profile'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/connections'),
                  icon: const Icon(Icons.people),
                  label: const Text('Connections'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
