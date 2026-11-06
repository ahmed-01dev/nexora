import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_error.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = Supabase.instance.client;
    final rows = await client
        .from('media')
        .select('id,storage_path,post_id,posts!media_post_id_fkey(id,content,visibility,user_id,profiles!posts_user_id_fkey(display_name,username))')
        .eq('media_type', 'video')
        .eq('posts.visibility', 'public')
        .order('created_at', ascending: false)
        .limit(40);

    final candidates = rows.where((row) => row['posts'] is Map).toList();
    final result = <Map<String, dynamic>>[];
    // Sign at most eight URLs concurrently and isolate inaccessible media.
    for (var start = 0; start < candidates.length; start += 8) {
      final end = (start + 8 < candidates.length)
          ? start + 8
          : candidates.length;
      final signedBatch = await Future.wait(
        candidates.sublist(start, end).map((row) async {
          final post = Map<String, dynamic>.from(row['posts'] as Map);
          final authorRaw = post['profiles'];
          final author = authorRaw is Map
              ? Map<String, dynamic>.from(authorRaw)
              : <String, dynamic>{};
          try {
            final url = await client.storage
                .from('nexora-media')
                .createSignedUrl(row['storage_path'] as String, 3600);
            return <String, dynamic>{
              'id': row['id'],
              'post_id': row['post_id'],
              'url': url,
              'caption': post['content'] ?? '',
              'author': author,
            };
          } catch (error, stack) {
            AppErrorService.report(error, stack, source: 'reel_signed_url');
            return null;
          }
        }),
      );
      result.addAll(signedBatch.whereType<Map<String, dynamic>>());
    }
    return result;
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _activeIndex = 0;
      _future = next;
    });
    try {
      await next;
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'reels_refresh');
      // FutureBuilder renders the error state; keep the refresh action resolved.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('ريلز', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'تعذر تحميل الفيديوهات',
              error: snapshot.error,
              onRetry: _refresh,
            );
          }
          final reels = snapshot.data ?? [];
          if (reels.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.video_library_outlined, color: Colors.white, size: 58),
                    SizedBox(height: 16),
                    Text('لسه مفيش ريلز عامة', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text(
                      'ارفع فيديو من شاشة إنشاء منشور واجعل جمهوره عامًا ليظهر هنا.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            onPageChanged: (index) => setState(() => _activeIndex = index),
            itemBuilder: (context, index) => _ReelPlayer(
              key: ValueKey(reels[index]['id']),
              reel: reels[index],
              active: index == _activeIndex,
            ),
          );
        },
      ),
    );
  }
}

class _ReelPlayer extends StatefulWidget {
  const _ReelPlayer({
    super.key,
    required this.reel,
    required this.active,
  });

  final Map<String, dynamic> reel;
  final bool active;

  @override
  State<_ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<_ReelPlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _muted = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.reel['url'] as String),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      if (widget.active) await _controller.play();
      if (mounted) setState(() => _ready = true);
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'reel_playback');
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void didUpdateWidget(covariant _ReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready || oldWidget.active == widget.active) return;
    _changeActiveState();
  }

  Future<void> _changeActiveState() async {
    try {
      if (widget.active) {
        await _controller.play();
      } else {
        await _controller.pause();
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'reel_active_state');
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (!_ready || _error != null) return;
    try {
      if (_controller.value.isPlaying) {
        await _controller.pause();
      } else {
        await _controller.play();
      }
      if (mounted) setState(() {});
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'reel_toggle_playback');
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _toggleMute() async {
    if (!_ready || _error != null) return;
    final nextMuted = !_muted;
    try {
      await _controller.setVolume(nextMuted ? 0 : 1);
      if (mounted) setState(() => _muted = nextMuted);
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'reel_toggle_mute');
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = widget.reel['author'] as Map<String, dynamic>;
    final name = (author['display_name'] ?? author['username'] ?? 'NEXORA creator').toString();
    final username = (author['username'] ?? 'creator').toString();
    final caption = (widget.reel['caption'] ?? '').toString();

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready)
            ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else if (_error == null)
            const ColoredBox(
              color: Color(0xFF080808),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            const ColoredBox(color: Color(0xFF080808)),
          if (_error != null)
            const Center(child: Text('الفيديو غير متاح حاليًا', style: TextStyle(color: Colors.white))),
          if (_ready && !_controller.value.isPlaying)
            const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 68),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 28,
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        Text('@$username', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        if (caption.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(caption, maxLines: 3, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _toggleMute,
                    icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
