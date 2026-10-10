import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final service = AdminService();
  bool allowed = false;
  bool loading = true;
  List<Map<String, dynamic>> reports = [];
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { allowed = await service.isAdmin(); if (allowed) reports = await service.pendingReports(); } finally { if (mounted) setState(() => loading = false); }
  }
  Future<void> _resolve(String id, String status) async { await service.resolveReport(id, status, 'Reviewed from admin dashboard'); await _load(); }
  @override Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!allowed) return const Scaffold(body: Center(child: Text('Admin access required.')));
    return Scaffold(appBar: AppBar(title: const Text('Admin Dashboard')), body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [Text('Open reports: ${reports.length}', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12), ...reports.map((r) => Card(child: ListTile(title: Text(r['reason']?.toString() ?? 'Report'), subtitle: Text('${r['content_type'] ?? 'content'} • ${r['status'] ?? ''}'), trailing: PopupMenuButton<String>(onSelected: (v) => _resolve(r['id'].toString(), v), itemBuilder: (_) => const [PopupMenuItem(value: 'resolved', child: Text('Resolve')), PopupMenuItem(value: 'dismissed', child: Text('Dismiss'))]))))])));
  }
}
