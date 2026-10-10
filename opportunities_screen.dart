import 'package:flutter/material.dart';
import '../repositories/opportunity_repository.dart';

class OpportunitiesScreen extends StatelessWidget {
  const OpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opportunities')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: OpportunityRepository().list(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Unable to load opportunities.\n${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return const Center(child: Text('No opportunities available yet.'));
          }
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final opportunity = rows[index];
              return ListTile(
                title: Text('${opportunity['title'] ?? ''}'),
                subtitle: Text('${opportunity['type'] ?? ''}'),
              );
            },
          );
        },
      ),
    );
  }
}
