import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});
  @override State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final values = <String, bool>{
    'messages': true, 'connections': true, 'events': true, 'opportunities': true,
    'education': true, 'marketplace': true, 'projects': true, 'system': true,
  };
  bool loading = true;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final row = await SupabaseService.client.from('notification_preferences').select().maybeSingle();
      if (row != null && mounted) {
        setState(() { for (final k in values.keys) { values[k] = row[k] == true; } loading = false; });
      } else if (mounted) setState(() => loading = false);
    } catch (_) { if (mounted) setState(() => loading = false); }
  }
  Future<void> _save() async {
    await SupabaseService.client.rpc('save_notification_preferences', params: {
      for (final e in values.entries) 'p_${e.key}': e.value,
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification settings saved.')));
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notification Settings')),
    body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
      children: [for (final key in values.keys) SwitchListTile(title: Text(_label(key)), value: values[key]!, onChanged: (v) => setState(() => values[key] = v)),
        Padding(padding: const EdgeInsets.all(16), child: FilledButton(onPressed: _save, child: const Text('Save')))],
    ),
  );
  String _label(String key) => key[0].toUpperCase() + key.substring(1);
}
