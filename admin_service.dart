import 'supabase_service.dart';

class AdminService {
  final db = SupabaseService.client;

  Future<bool> isAdmin() async {
    final result = await db.rpc('is_platform_admin');
    return result == true;
  }

  Future<List<Map<String, dynamic>>> pendingReports() async {
    return List<Map<String, dynamic>>.from(
      await db.from('safety_reports').select().inFilter('status', ['open', 'reviewing']).order('created_at', ascending: false),
    );
  }

  Future<String> resolveReport(String id, String status, String note) async {
    final result = await db.rpc('admin_resolve_report', params: {
      'p_report_id': id,
      'p_status': status,
      'p_note': note,
    });
    return result.toString();
  }
}
