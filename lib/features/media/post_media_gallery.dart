import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_error.dart';

class PostMediaGallery extends StatefulWidget {
  const PostMediaGallery({super.key, required this.postId});

  final String postId;

  @override
  State<PostMediaGallery> createState() => _PostMediaGalleryState();
}

class _PostMediaGalleryState extends State<PostMediaGallery> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = Supabase.instance.client;
    final rows = await client
        .from('media')
        .select('media_type,storage_path,position')
        .eq('post_id', widget.postId)
        .order('position');
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      final path = row['storage_path'] as String;
      final url = await client.storage
          .from('nexora-media')
          .createSignedUrl(path, 3600);
      result.add({
        'media_type': row['media_type'],
        'url': url,
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        if (snapshot.hasError) {
          AppErrorService.report(snapshot.error!, snapshot.stackTrace, source: 'load_post_media');
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('تعذر تحميل الوسائط. اسحب للتحديث وحاول تاني.',
                style: TextStyle(color: Colors.grey)),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: item['media_type'] == 'video'
                      ? _NetworkVideo(url: item['url'] as String)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            item['url'] as String,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                    ? child
                                    : const SizedBox(
                                        height: 220,
                                        child: Center(child: CircularProgressIndicator()),
                                      ),
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 180,
                              child: Center(child: Icon(Icons.broken_image_outlined, size: 40)),
                            ),
                          ),
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NetworkVideo extends StatefulWidget {
  const _NetworkVideo({required this.url});

  final String url;

  @override
  State<_NetworkVideo> createState() => _NetworkVideoState();
}

class _NetworkVideoState extends State<_NetworkVideo> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialized;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initialized = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialized,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox(
            height: 180,
            child: Center(child: Text('تعذر تشغيل الفيديو')),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                IconButton.filledTonal(
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                  icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 4,
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
