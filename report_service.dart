import 'supabase_service.dart';

class ReportService {
  Future<String> report({
    required String contentType,
    required String contentId,
    required String reason,
    String details = '',
  }) async {
    final result = await SupabaseService.client.rpc('create_content_report', params: {
      'p_content_type': contentType,
      'p_content_id': contentId,
      'p_reason': reason,
      'p_details': details,
    });
    return result as String;
  }
}
