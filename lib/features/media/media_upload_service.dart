import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaUploadService {
  MediaUploadService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  static const int maxBytes = 50 * 1024 * 1024;
  static const int maxFiles = 10;


  static const int maxProfileImageBytes = 10 * 1024 * 1024;

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
    final path = '$userId/profile/${imageType}_${DateTime.now().microsecondsSinceEpoch}.$extension';
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
    if (files.length > maxFiles) {
      throw const FormatException('الحد الأقصى 10 ملفات في المنشور.');
    }
    final client = Supabase.instance.client;
    final uploaded = <String>[];
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
        final path = '$userId/$postId/${DateTime.now().microsecondsSinceEpoch}_$i.$extension';
        await client.storage.from('nexora-media').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: details.$2, upsert: false),
        );
        uploaded.add(path);
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
    final path = '$userId/stories/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await Supabase.instance.client.storage.from('nexora-media').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: details.$2, upsert: false),
    );
    return path;
  }

  Future<void> removeUploaded(List<String> paths) async {
    if (paths.isEmpty) return;
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
