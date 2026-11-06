import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';

class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({super.key});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  static const int _pageSize = 30;

  List<Map<String, dynamic>> _requests = [];
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _nextOffset = 0;
  int _requestGeneration = 0;
  String? _error;
  final Set<String> _accepting = {};

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<List<Map<String, dynamic>>> _fetchPage(int offset) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('يجب تسجيل الدخول لعرض طلبات المتابعة.');

    final rows = await client
        .from('follows')
        .select('follower_id,created_at,profiles!follows_follower_id_fkey(id,username,display_name,avatar_url,is_verified)')
        .eq('following_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .order('follower_id', ascending: true)
        .range(offset, offset + _pageSize - 1);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _loadFirstPage() async {
    final generation = ++_requestGeneration;
    setState(() {
      _initialLoading = true;
      _loadingMore = false;
      _error = null;
      _hasMore = true;
      _nextOffset = 0;
    });
    try {
      final rows = await _fetchPage(0);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _requests = rows;
        _nextOffset = rows.length;
        _hasMore = rows.length == _pageSize;
        _initialLoading = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'follow_requests_load');
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error = AppErrorService.message(error);
        _initialLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    final generation = ++_requestGeneration;
    setState(() {
      _refreshing = true;
      _loadingMore = false;
    });
    try {
      final rows = await _fetchPage(0);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _requests = rows;
        _nextOffset = rows.length;
        _hasMore = rows.length == _pageSize;
        _error = null;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'follow_requests_refresh');
      if (!mounted || generation != _requestGeneration) return;
      if (_requests.isEmpty) {
        setState(() => _error = AppErrorService.message(error));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _initialLoading || _refreshing) return;
    final generation = _requestGeneration;
    setState(() => _loadingMore = true);
    try {
      final rows = await _fetchPage(_nextOffset);
      if (!mounted || generation != _requestGeneration) return;
      final known = _requests.map((row) => row['follower_id']).toSet();
      final additions = rows.where((row) => !known.contains(row['follower_id']));
      setState(() {
        _requests = [..._requests, ...additions];
        _nextOffset += rows.length;
        _hasMore = rows.length == _pageSize;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'follow_requests_load_more');
      if (!mounted || generation != _requestGeneration) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorService.message(error))),
      );
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _accept(Map<String, dynamic> request) async {
    final followerId = request['follower_id']?.toString();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (followerId == null || userId == null || _refreshing || _initialLoading || _accepting.contains(followerId)) {
      return;
    }

    setState(() => _accepting.add(followerId));
    try {
      final updated = await Supabase.instance.client
          .from('follows')
          .update({'status': 'accepted'})
          .eq('follower_id', followerId)
          .eq('following_id', userId)
          .eq('status', 'pending')
          .select('follower_id')
          .maybeSingle();

      if (updated == null) {
        throw StateError('تعذر قبول الطلب. ربما ألغاه صاحبه أو تم حظره.');
      }
      if (!mounted) return;
      setState(() {
        _requests.removeWhere((row) => row['follower_id'] == followerId);
        _accepting.remove(followerId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قبول طلب المتابعة.')),
      );
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'follow_request_accept');
      if (!mounted) return;
      setState(() => _accepting.remove(followerId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorService.message(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات المتابعة'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _initialLoading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorView(
                  title: 'تعذر تحميل طلبات المتابعة',
                  error: _error,
                  onRetry: _loadFirstPage,
                )
              : _requests.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 140),
                          Icon(Icons.person_add_alt_1_outlined, size: 52, color: Colors.grey),
                          SizedBox(height: 16),
                          Center(
                            child: Text(
                              'مفيش طلبات متابعة جديدة.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length + (_hasMore || _loadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == _requests.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: _loadingMore
                                    ? const CircularProgressIndicator()
                                    : OutlinedButton(
                                        onPressed: _loadMore,
                                        child: const Text('تحميل المزيد'),
                                      ),
                              ),
                            );
                          }
                          final request = _requests[index];
                          final profile = request['profiles'] is Map
                              ? Map<String, dynamic>.from(request['profiles'] as Map)
                              : <String, dynamic>{};
                          final followerId = request['follower_id']?.toString() ?? '';
                          final profileHidden = profile.isEmpty;
                          final username = (profile['username'] ?? 'user').toString();
                          final displayName = profileHidden
                              ? 'حساب خاص'
                              : (profile['display_name'] ?? username).toString();
                          final followerLabel = followerId.length > 6
                              ? followerId.substring(0, 6)
                              : followerId;

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  displayName.isEmpty
                                      ? '?'
                                      : displayName.characters.first,
                                ),
                              ),
                              title: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(profileHidden ? 'الملف الشخصي غير متاح · $followerLabel' : '@$username'),
                              trailing: FilledButton.tonalIcon(
                                onPressed: _refreshing || _accepting.contains(followerId)
                                    ? null
                                    : () => _accept(request),
                                icon: _accepting.contains(followerId)
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.check),
                                label: const Text('قبول'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
