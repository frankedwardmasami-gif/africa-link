import 'dart:typed_data';
import 'supabase_service.dart';

class StorageService {
  Future<String> uploadAvatar(String userId, Uint8List bytes) async {
    final path = '$userId/avatar';
    await SupabaseService.client.storage.from('avatars').uploadBinary(
      path, bytes, fileOptions: const FileOptions(upsert: true));
    return await SupabaseService.client.storage.from('avatars').createSignedUrl(path, 3600);
  }
}
