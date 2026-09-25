import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AiService {
  Future<String> ask(String prompt) async {
    final res = await SupabaseService.client.functions.invoke(
      'ai-proxy',
      body: {'prompt': prompt},
    );
    final data = res.data;
    if (data is Map && data['answer'] != null) return data['answer'];
    throw const FunctionsException('AI service returned no answer');
  }
}
