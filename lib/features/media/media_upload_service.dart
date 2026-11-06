import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaUploadService {
  MediaUploadService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static void validateUploadOwner({
    required String? authenticatedUserId,
    required String requestedUserId,
  }) {
    if (authenticatedUserId == null || authenticatedUserId != requestedUserId) {
      throw StateError('يجب استخدام الحساب المسجل حاليًا لرفع الملفات.');
    }
  }

  void _requireCurrentUser(String userId) {
    validateUploadOwner(
      authenticatedUserId: Supabase.instance.client.auth.currentUser?.id,
      requestedUserId: userId,
    );
  }

  static const int maxBytes = 50 * 1024 * 1024;
  static const int maxFiles = 10;
  static const int maxPostTotalBytes = 100 * 1024 * 1024;


  static const int maxProfileImageBytes = 10 * 1024 * 1024;

  /// Checks the actual file signature instead of trusting its extension.
  static bool hasValidImageSignature(String extension, List<int> bytes) {
    final ext = extension.toLowerCase();
    if (ext == 'jpg' || ext == 'jpeg') {
      return bytes.length >= 3 &&
          bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
    }
    if (ext == 'png') {
      const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      if (bytes.length < signature.length) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[i] != signature[i]) return false;
      }
      return true;
    }
    if (ext == 'webp') {
      return bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
    }
    if (ext == 'gif') {
      if (bytes.length < 6) return false;
      final signature = String.fromCharCodes(bytes.sublist(0, 6));
      return signature == 'GIF87a' || signature == 'GIF89a';
    }
    return false;
  }

  /// Lightweight client-side media signature check; server-side scanning is
  /// still required because a modified client can bypass this validation.
  static bool hasValidMediaSignature(String extension, List<int> bytes) {
    final ext = extension.toLowerCase();
    if (const {'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(ext)) {
      return hasValidImageSignature(ext, bytes);
    }
    if (ext == 'mp4') {
      return bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp';
    }
    if (ext == 'webm') {
      return bytes.length >= 4 &&
          bytes[0] == 0x1A &&
          bytes[1] == 0x45 &&
          bytes[2] == 0xDF &&
          bytes[3] == 0xA3;
    }
    return false;
  }

  Future<XFile?> pickProfileImage() => _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 2048,
        maxHeight: 2048,
      );

  Future<String> uploadProfileImage({
    required String userId,
    required XFile file,
    required String imageType,
  }) async {
    _requireCurrentUser(userId);
    if (imageType != 'avatar' && imageType != 'cover') {
      throw const FormatException('نوع صورة الملف الشخصي غير صالح.');
    }
    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : '';
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
    if (contentType == null) {
      throw FormatException('استخدم صورة JPG أو PNG أو WebP: ${file.name}');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > maxProfileImageBytes) {
      throw const FormatException('حجم صورة الملف الشخصي يجب ألا يتجاوز 10 ميجابايت.');
    }
    if (!hasValidImageSignature(extension, bytes)) {
      throw const FormatException('محتوى الصورة لا يطابق امتداد الملف. اختر صورة JPG أو PNG أو WebP سليمة.');
    }
    final path = '$userId/profile/${imageType}_${DateTime.now().microsecondsSinceEpoch}.$extension';
    _requireCurrentUser(userId);
    await Supabase.instance.client.storage.from('nexora-media').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );
    return path;
  }

  Future<void> removeProfileImage(String path) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || !path.startsWith('$userId/profile/')) return;
    await Supabase.instance.client.storage.from('nexora-media').remove([path]);
  }

  Future<List<XFile>> pickImages() async {
    return _picker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 2048,
      maxHeight: 2048,
    );
  }

  Future<XFile?> pickVideo() {
    return _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
  }

  Future<List<String>> uploadPostMedia({
    required String userId,
    required String postId,
    required List<XFile> files,
  }) async {
    _requireCurrentUser(userId);
    if (files.length > maxFiles) {
      throw const FormatException('الحد الأقصى 10 ملفات في المنشور.');
    }
    final client = Supabase.instance.client;
    final uploaded = <String>[];
    var totalBytes = 0;
    try {
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final extension = file.name.contains('.')
            ? file.name.split('.').last.toLowerCase()
            : '';
        final details = _typeFor(extension);
        if (details == null) {
          throw FormatException('نوع الملف غير مدعوم: ${file.name}');
        }
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty || bytes.length > maxBytes) {
          throw FormatException('حجم الملف غير صالح أو أكبر من 50 ميجابايت: ${file.name}');
        }
        totalBytes += bytes.length;
        if (totalBytes > maxPostTotalBytes) {
          throw const FormatException('إجمالي وسائط المنشور لا يمكن أن يتجاوز 100 ميجابايت.');
        }
        if (!hasValidMediaSignature(extension, bytes)) {
          throw FormatException('محتوى الملف لا يطابق نوعه: ${file.name}');
        }
        final path = '$userId/$postId/${DateTime.now().microsecondsSinceEpoch}_$i.$extension';
        _requireCurrentUser(userId);
        await client.storage.from('nexora-media').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: details.$2, upsert: false),
        );
        uploaded.add(path);
        _requireCurrentUser(userId);
        await client.from('media').insert({
          'post_id': postId,
          'user_id': userId,
          'media_type': details.$1,
          'storage_path': path,
          'position': i,
        });
      }
      return uploaded;
    } catch (_) {
      // Remove any metadata rows created before a later file failed. The
      // caller also removes the parent post, but the service remains safe
      // when reused independently.
      try {
        await client
            .from('media')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } catch (_) {
        // Preserve the original upload error; parent-post cleanup can retry.
      }
      if (uploaded.isNotEmpty) {
        try {
          await client.storage.from('nexora-media').remove(uploaded);
        } catch (_) {
          // Preserve the original failure; orphan cleanup can be retried server-side.
        }
      }
      rethrow;
    }
  }

  Future<String> uploadStoryMedia({
    required String userId,
    required XFile file,
  }) async {
    _requireCurrentUser(userId);
    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : '';
    final details = _typeFor(extension);
    if (details == null) {
      throw FormatException('نوع الملف غير مدعوم: ${file.name}');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw FormatException('حجم الملف غير صالح أو أكبر من 50 ميجابايت: ${file.name}');
    }
    if (!hasValidMediaSignature(extension, bytes)) {
      throw FormatException('محتوى الملف لا يطابق نوعه: ${file.name}');
    }
    final path = '$userId/stories/${DateTime.now().microsecondsSinceEpoch}.$extension';
    _requireCurrentUser(userId);
    await Supabase.instance.client.storage.from('nexora-media').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: details.$2, upsert: false),
    );
    return path;
  }

  Future<void> removeUploaded(List<String> paths) async {
    if (paths.isEmpty) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null ||
        paths.any((path) => !path.startsWith('$userId/'))) {
      throw StateError('لا يمكن حذف ملفات لا تخص الحساب الحالي.');
    }
    await Supabase.instance.client.storage.from('nexora-media').remove(paths);
  }

  (String, String)? _typeFor(String extension) {
    return switch (extension) {
      'jpg' || 'jpeg' => ('image', 'image/jpeg'),
      'png' => ('image', 'image/png'),
      'webp' => ('image', 'image/webp'),
      'gif' => ('image', 'image/gif'),
      'mp4' => ('video', 'video/mp4'),
      'webm' => ('video', 'video/webm'),
      _ => null,
    };
  }
}
