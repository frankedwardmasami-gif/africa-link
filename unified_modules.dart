import 'package:flutter/material.dart';
import '../services/module_service.dart';
import 'module_detail.dart';

class UnifiedModules extends StatelessWidget {
  const UnifiedModules({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Africa')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        children: [
          _tile(context, 'Communities', 'communities', Icons.groups),
          _tile(context, 'Events', 'events', Icons.event),
          _tile(context, 'Education', 'courses', Icons.school),
          _tile(context, 'Business', 'businesses', Icons.store),
          _tile(context, 'Funding', 'funding_opportunities', Icons.account_balance),
          _tile(context, 'Projects', 'projects', Icons.engineering),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String table, IconData icon) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ModuleList(title: title, table: table)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38),
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class ModuleList extends StatelessWidget {
  final String title;
  final String table;

  const ModuleList({super.key, required this.title, required this.table});

  Future<List<Map<String, dynamic>>> _load() => ModuleService().list(table);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Unable to load $title.\n${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return Center(child: Text('No $title available yet.'));
          }
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final item = rows[index];
              final subtitle = item['country'] ??
                  item['description'] ??
                  item['type'] ??
                  item['status'] ??
                  '';
              return Card(
                child: ListTile(
                  title: Text('${item['name'] ?? item['title'] ?? 'Item'}'),
                  subtitle: Text('$subtitle'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ModuleDetail(module: table, item: item),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
