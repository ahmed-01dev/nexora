import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../media/media_upload_service.dart';

class MessageAttachmentService {
  final ImagePicker _picker = ImagePicker();
  Future<XFile?> pickImage() => _picker.pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 2048, maxHeight: 2048);

  Future<String> sendImage(String conversationId, XFile file) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser!.id;
    final ext = file.name.split('.').last.toLowerCase();
    final type = switch (ext) { 'jpg' || 'jpeg' => 'image/jpeg', 'png' => 'image/png', 'webp' => 'image/webp', _ => null };
    if (type == null) throw const FormatException('صيغة الصورة غير مدعومة.');
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024 || !MediaUploadService.hasValidImageSignature(ext, bytes)) {
      throw const FormatException('الصورة غير صالحة أو أكبر من 10 ميجابايت.');
    }
    final path = '$uid/$conversationId/messages/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await client.storage.from('nexora-media').uploadBinary(path, bytes, fileOptions: FileOptions(contentType: type, upsert: false));
    String? messageId;
    try {
      final row = await client.from('messages').insert({'conversation_id': conversationId, 'sender_id': uid, 'message_type': 'image', 'body': null, 'encryption_mode': 'server_readable'}).select('id').single();
      messageId = row['id'] as String;
      await client.from('message_attachments').insert({'message_id': messageId, 'uploader_id': uid, 'storage_path': path, 'mime_type': type, 'size_bytes': bytes.length});
      return messageId;
    } catch (_) {
      if (messageId != null) {
        try {
          await client.from('messages')
              .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
              .eq('id', messageId)
              .eq('sender_id', uid);
        } catch (_) {}
      }
      try { await client.storage.from('nexora-media').remove([path]); } catch (_) {}
      rethrow;
    }
  }

  Future<String?> signedImageUrl(String messageId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final row = await Supabase.instance.client.from('message_attachments').select('storage_path').eq('message_id', messageId).maybeSingle();
    final path = row?['storage_path'] as String?;
    if (path == null) return null;
    return Supabase.instance.client.storage.from('nexora-media').createSignedUrl(path, 3600);
  }

  Future<void> deleteOwnAttachment(String messageId) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    final row = await client.from('message_attachments')
        .select('storage_path')
        .eq('message_id', messageId)
        .eq('uploader_id', uid)
        .maybeSingle();
    final path = row?['storage_path'] as String?;
    if (path == null) return;
    await client.from('message_attachments')
        .delete()
        .eq('message_id', messageId)
        .eq('uploader_id', uid);
    try { await client.storage.from('nexora-media').remove([path]); } catch (_) {}
  }
}
