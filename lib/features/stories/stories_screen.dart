import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_error.dart';
import '../media/media_upload_service.dart';
import '../moderation/report_dialog.dart';
import '../blocks/block_account_service.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = Supabase.instance.client;
    final rows = await client
        .from('stories')
        .select('id,user_id,media_path,text_content,story_type,visibility,created_at,expires_at,profiles!stories_user_id_fkey(display_name,username)')
        .isFilter('archived_at', null)
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .limit(100);
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      final item = Map<String, dynamic>.from(row);
      if (item['media_path'] != null) {
        item['signed_url'] = await client.storage
            .from('nexora-media')
            .createSignedUrl(item['media_path'] as String, 3600);
      }
      result.add(item);
    }
    return result;
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const StoryComposerScreen()),
    );
    if (created == true && mounted) setState(() => _future = _load());
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _open(Map<String, dynamic> story) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => StoryViewerScreen(story: story),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القصص'),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('قصتك'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppErrorView(title: 'تعذر تحميل القصص', error: snapshot.error, onRetry: _refresh);
          }
          final stories = snapshot.data ?? [];
          if (stories.isEmpty) {
            return const Center(child: Text('مفيش قصص متاحة. شارك أول قصة مع متابعينك.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: stories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final story = stories[index];
                final profile = story['profiles'] is Map
                    ? Map<String, dynamic>.from(story['profiles'] as Map)
                    : <String, dynamic>{};
                final name = (profile['display_name'] ?? profile['username'] ?? 'مستخدم').toString();
                final isText = story['story_type'] == 'text';
                return Card(
                  child: ListTile(
                    onTap: () => _open(story),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(isText ? Icons.text_fields : Icons.auto_awesome),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(isText ? (story['text_content'] ?? 'قصة نصية').toString() : 'قصة ${story['story_type'] == 'video' ? 'فيديو' : 'صورة'}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_left),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class StoryComposerScreen extends StatefulWidget {
  const StoryComposerScreen({super.key});

  @override
  State<StoryComposerScreen> createState() => _StoryComposerScreenState();
}

class _StoryComposerScreenState extends State<StoryComposerScreen> {
  final _text = TextEditingController();
  final _media = MediaUploadService();
  XFile? _file;
  String _visibility = 'followers';
  bool _busy = false;
  String? _error;

  Future<void> _pickImage() async {
    try {
      final files = await _media.pickImages();
      if (mounted && files.isNotEmpty) setState(() { _file = files.first; _error = null; });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'story_pick_image');
      if (mounted) setState(() => _error = AppErrorService.message(error));
    }
  }

  Future<void> _pickVideo() async {
    try {
      final file = await _media.pickVideo();
      if (mounted && file != null) setState(() { _file = file; _error = null; });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'story_pick_video');
      if (mounted) setState(() => _error = AppErrorService.message(error));
    }
  }

  Future<void> _publish() async {
    final text = _text.text.trim();
    if (_file == null && text.isEmpty) {
      setState(() => _error = 'أضف نصًا أو صورة أو فيديو.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _error = 'انتهت جلسة الدخول. سجّل الدخول مرة تانية.');
      return;
    }
    String? path;
    try {
      if (_file != null) {
        path = await _media.uploadStoryMedia(userId: userId, file: _file!);
      }
      final isVideo = _file?.name.toLowerCase().endsWith('.mp4') == true ||
          _file?.name.toLowerCase().endsWith('.webm') == true;
      if (client.auth.currentUser?.id != userId) {
        throw StateError('تغير الحساب أثناء رفع القصة. سجّل الدخول مرة تانية.');
      }
      await client.from('stories').insert({
        'user_id': userId,
        'media_path': path,
        'text_content': text.isEmpty ? null : text,
        'story_type': _file == null ? 'text' : (isVideo ? 'video' : 'photo'),
        'visibility': _visibility,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'publish_story');
      if (path != null) {
        try { await _media.removeUploaded([path]); }
        catch (cleanupError, cleanupStack) {
          AppErrorService.report(cleanupError, cleanupStack, source: 'story_media_cleanup');
        }
      }
      if (mounted) setState(() => _error = AppErrorService.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء قصة')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _text,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            decoration: const InputDecoration(labelText: 'اكتب شيئًا لقصة اليوم'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(onPressed: _busy ? null : _pickImage, icon: const Icon(Icons.image_outlined), label: const Text('صورة')),
              OutlinedButton.icon(onPressed: _busy ? null : _pickVideo, icon: const Icon(Icons.video_library_outlined), label: const Text('فيديو')),
            ],
          ),
          if (_file != null)
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(_file!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(onPressed: _busy ? null : () => setState(() => _file = null), icon: const Icon(Icons.close)),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _visibility,
            decoration: const InputDecoration(labelText: 'من يشاهد القصة؟'),
            items: const [
              DropdownMenuItem(value: 'public', child: Text('الجميع')),
              DropdownMenuItem(value: 'followers', child: Text('المتابعون')),
            ],
            onChanged: _busy ? null : (value) => setState(() => _visibility = value ?? 'followers'),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _publish,
            child: _busy ? const CircularProgressIndicator() : const Text('نشر القصة لمدة 24 ساعة'),
          ),
        ],
      ),
    );
  }
}

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({super.key, required this.story});
  final Map<String, dynamic> story;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  VideoPlayerController? _video;
  Future<void>? _videoReady;

  @override
  void initState() {
    super.initState();
    _markViewed();
    if (widget.story['story_type'] == 'video' && widget.story['signed_url'] != null) {
      _video = VideoPlayerController.networkUrl(Uri.parse(widget.story['signed_url'] as String));
      _videoReady = _video!.initialize().then((_) => _video!.play());
    }
  }

  Future<void> _markViewed() async {
    final viewerId = Supabase.instance.client.auth.currentUser?.id;
    if (viewerId == null) return;
    try {
      await Supabase.instance.client.from('story_views').insert({
        'story_id': widget.story['id'],
        'viewer_id': viewerId,
      });
    } catch (error, stack) {
      if (!error.toString().contains('23505')) {
        AppErrorService.report(error, stack, source: 'story_view');
      }
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = (widget.story['text_content'] ?? '').toString();
    final url = widget.story['signed_url'] as String?;
    final viewerId = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('NEXORA Story'),
        actions: [
          if (viewerId != null && widget.story['user_id'] != viewerId)
            IconButton(
              tooltip: 'حظر صاحب القصة',
              onPressed: () async {
                try {
                  final blocked = await BlockAccountService.confirmAndBlock(
                    context,
                    targetUserId: widget.story['user_id'] as String,
                    displayName: 'صاحب القصة',
                  );
                  if (blocked && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حظر الحساب')),
                    );
                  }
                } catch (error, stack) {
                  AppErrorService.report(error, stack, source: 'block_story_author');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppErrorService.message(error))),
                    );
                  }
                }
              },
              icon: const Icon(Icons.block_outlined),
            ),
          if (viewerId != null && widget.story['user_id'] != viewerId)
            IconButton(
              tooltip: 'الإبلاغ عن القصة',
              onPressed: () async {
                final submitted = await ReportDialog.show(
                  context,
                  targetType: 'story',
                  targetId: widget.story['id'] as String,
                );
                if (submitted && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال البلاغ للمراجعة')),
                  );
                }
              },
              icon: const Icon(Icons.flag_outlined),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.story['story_type'] == 'video' && _video != null)
            FutureBuilder<void>(
              future: _videoReady,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'تعذر تشغيل الفيديو.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Center(
                  child: AspectRatio(
                    aspectRatio: _video!.value.aspectRatio,
                    child: VideoPlayer(_video!),
                  ),
                );
              },
            )
          else if (url != null)
            Center(child: Image.network(url, fit: BoxFit.contain))
          else
            const ColoredBox(color: Color(0xFF151515)),
          if (text.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: Colors.black54,
                child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}
