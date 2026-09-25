import 'dart:typed_data';
import 'supabase_service.dart';

class MediaService {
  Future<Map<String, dynamic>> registerUpload({
    required String bucket,
    required String objectPath,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    if (!{'avatars', 'media', 'documents'}.contains(bucket)) {
      throw ArgumentError('Unsupported media bucket');
    }
    if (bytes.isEmpty) throw ArgumentError('Empty file');
    if (bytes.length > 15 * 1024 * 1024) throw ArgumentError('File exceeds 15 MB limit');
    await SupabaseService.client.storage.from(bucket).uploadBinary(
      objectPath,
      bytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: false),
    );
    final row = await SupabaseService.client.from('media_assets').insert({
      'owner_id': SupabaseService.client.auth.currentUser!.id,
      'bucket': bucket,
      'object_path': objectPath,
      'mime_type': mimeType,
      'size_bytes': bytes.length,
    }).select().single();
    return row;
  }

  Future<String> createSignedUrl(String bucket, String objectPath, {int expiresIn = 900}) {
    if (expiresIn < 60 || expiresIn > 86400) {
      throw ArgumentError('expiresIn must be between 60 and 86400 seconds');
    }
    return SupabaseService.client.storage.from(bucket).createSignedUrl(objectPath, expiresIn);
  }
}
