import 'package:flutter/material.dart';
import '../services/advanced_social_service.dart';
import 'public_profile_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final api = AdvancedSocialService();
  bool loading = true;
  List<Map<String, dynamic>> connections = [];
  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      connections = await api.connections();
      requests = await api.incomingRequests();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget person(Map<String, dynamic> profile, {bool request = false}) {
    final id = '${profile['id']}';
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text('${profile['full_name'] ?? ''}'),
      subtitle: Text('@${profile['username'] ?? ''}'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PublicProfileScreen(profile: profile)),
      ),
      trailing: request
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    await api.respond(id, false);
                    await _load();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () async {
                    await api.respond(id, true);
                    await _load();
                  },
                ),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.person_remove_outlined),
              onPressed: () async {
                await api.removeConnection(id);
                await _load();
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connections')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (requests.isNotEmpty) ...[
                    const Text(
                      'Requests',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ...requests.map((profile) => person(profile, request: true)),
                    const Divider(),
                  ],
                  const Text(
                    'My connections',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (connections.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No connections yet.'),
                    ),
                  ...connections.map(person),
                ],
              ),
            ),
    );
  }
}
