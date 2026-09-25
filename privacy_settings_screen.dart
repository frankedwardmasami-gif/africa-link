import 'package:flutter/material.dart';
import '../services/privacy_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});
  @override State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final service = PrivacyService();
  String visibility = 'public';
  String messages = 'connections';
  bool online = true;
  bool requests = true;
  bool marketing = false;
  bool loading = true;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await service.getPreferences();
    if (p != null && mounted) setState(() {
      visibility = p['profile_visibility'] ?? visibility;
      messages = p['allow_direct_messages'] ?? messages;
      online = p['show_online_status'] ?? online;
      requests = p['allow_connection_requests'] ?? requests;
      marketing = p['marketing_notifications'] ?? marketing;
    });
    if (mounted) setState(() => loading = false);
  }
  Future<void> _save() async {
    await service.save(profileVisibility: visibility, showOnlineStatus: online, allowConnectionRequests: requests, allowDirectMessages: messages, marketingNotifications: marketing);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy settings saved')));
  }
  Future<void> _delete() async {
    await service.requestDeletion('User requested account deletion');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deletion request submitted')));
  }
  @override Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(appBar: AppBar(title: const Text('Privacy & Account')), body: ListView(padding: const EdgeInsets.all(16), children: [
      DropdownButtonFormField<String>(value: visibility, decoration: const InputDecoration(labelText: 'Profile visibility'), items: const [DropdownMenuItem(value: 'public', child: Text('Public')), DropdownMenuItem(value: 'connections', child: Text('Connections only')), DropdownMenuItem(value: 'private', child: Text('Private'))], onChanged: (v) => setState(() => visibility = v!)),
      DropdownButtonFormField<String>(value: messages, decoration: const InputDecoration(labelText: 'Direct messages'), items: const [DropdownMenuItem(value: 'everyone', child: Text('Everyone')), DropdownMenuItem(value: 'connections', child: Text('Connections')), DropdownMenuItem(value: 'nobody', child: Text('Nobody'))], onChanged: (v) => setState(() => messages = v!)),
      SwitchListTile(title: const Text('Show online status'), value: online, onChanged: (v) => setState(() => online = v)),
      SwitchListTile(title: const Text('Allow connection requests'), value: requests, onChanged: (v) => setState(() => requests = v)),
      SwitchListTile(title: const Text('Marketing notifications'), value: marketing, onChanged: (v) => setState(() => marketing = v)),
      const SizedBox(height: 12), FilledButton(onPressed: _save, child: const Text('Save settings')),
      const SizedBox(height: 24), const Divider(), const Text('Danger zone', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), OutlinedButton(onPressed: () async { final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Request account deletion?'), content: const Text('Your account will be queued for review. This action does not immediately delete your account.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Request deletion'))])); if (ok == true) await _delete(); }, child: const Text('Request account deletion')),
    ]));
  }
}
