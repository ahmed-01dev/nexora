import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_error.dart';
import 'core/theme/nexora_theme.dart';
import 'features/media/media_upload_service.dart';
import 'features/media/post_media_gallery.dart';
import 'features/friends/friend_requests_screen.dart';
import 'features/comments/comments_screen.dart';
import 'features/messaging/messages_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/reels/reels_screen.dart';
import 'features/settings/privacy_settings_screen.dart';
import 'features/stories/stories_screen.dart';
import 'features/search/hashtag_service.dart';
import 'features/communities/communities_screen.dart';

final _url = String.fromEnvironment('SUPABASE_URL').trim();
const _key = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorService.install();
  var ready = false;
  try {
    if (_url.startsWith('https://') && _key.isNotEmpty) {
      await Supabase.initialize(url: _url, anonKey: _key);
      ready = true;
    }
  } catch (e, s) { AppErrorService.report(e, s, source: 'startup'); }
  runApp(NexoraApp(ready: ready));
}

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key, required this.ready});
  final bool ready;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NEXORA', debugShowCheckedModeBanner: false,
    theme: NexoraTheme.light,
    darkTheme: NexoraTheme.amoled,
    themeMode: ThemeMode.dark,
    home: Directionality(textDirection: TextDirection.rtl, child: ready ? const AuthGate() : const _Setup()),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: Supabase.instance.client.auth.onAuthStateChange,
    builder: (context, snap) => (snap.data?.session ?? Supabase.instance.client.auth.currentSession) == null ? const AuthScreen() : const MainShell(),
  );
}

class _Setup extends StatelessWidget {
  const _Setup();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
          child: const _Empty(
            icon: Icons.settings,
            title: 'NEXORA محتاج إعداد الاتصال',
            subtitle: 'راجع متغيرات SUPABASE_URL وSUPABASE_ANON_KEY في إعدادات البناء. لا تضع service_role داخل التطبيق.',
          ),
        ),
      ),
    ),
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), _password = TextEditingController();
  bool _register = true, _busy = false, _visible = false;
  String? _error, _notice;
  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; _notice = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (_register) {
        final r = await auth.signUp(email: _email.text.trim(), password: _password.text, data: {'display_name': _name.text.trim()});
        if (r.session == null && mounted) setState(() => _notice = 'الحساب اتعمل. راجع بريدك لتأكيده وبعدها سجّل الدخول.');
      } else {
        await auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      }
    } on AuthException catch (e) { if (mounted) setState(() => _error = e.message); }
    catch (e, s) { AppErrorService.report(e, s, source: 'auth'); if (mounted) setState(() => _error = AppErrorService.message(e)); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: _Brand(size: 82)),
                    const SizedBox(height: 20),
                    const Text('NEXORA', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 4)),
                    const SizedBox(height: 8),
                    Text(_register ? 'مساحتك. صوتك. عالمك.' : 'رجعت تنوّر عالمك',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFA1A1AA))),
                    const SizedBox(height: 30),
                    if (_register) ...[
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'اسمك الظاهر', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => v == null || v.trim().length < 2 ? 'اكتب اسم من حرفين على الأقل' : null,
                      ),
                      const SizedBox(height: 13),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.alternate_email)),
                      validator: (v) => v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? 'اكتب بريد إلكتروني صحيح' : null,
                    ),
                    const SizedBox(height: 13),
                    TextFormField(
                      controller: _password,
                      obscureText: !_visible,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _visible = !_visible),
                          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (v) => v == null || v.length < 8 ? '8 أحرف على الأقل' : null,
                    ),
                    if (_error != null) _Notice(text: _error!, error: true),
                    if (_notice != null) _Notice(text: _notice!, error: false),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                      child: _busy
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_register ? 'إنشاء حساب' : 'تسجيل الدخول'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() { _register = !_register; _error = null; _notice = null; }),
                      child: Text(_register ? 'عندك حساب؟ سجّل الدخول' : 'مستخدم جديد؟ أنشئ حساب'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  int _tab = 0, _feedVersion = 0;
  void _posted() => setState(() { _tab = 0; _feedVersion++; });
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[HomeScreen(key: ValueKey(_feedVersion)), const ExploreScreen(), CreateScreen(onPosted: _posted), const ReelsScreen(), const MessagesScreen(), const ProfileScreen()];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(selectedIndex: _tab, onDestinationSelected: (v) => setState(() => _tab = v), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'استكشاف'),
        NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'إنشاء'),
        NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle), label: 'ريلز'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'الرسائل'),
        NavigationDestination(icon: Icon(Icons.account_circle_outlined), selectedIcon: Icon(Icons.account_circle), label: 'حسابي'),
      ]),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _FeedMode { latest, following }

class _HomeScreenState extends State<HomeScreen> {
  static const int _pageSize = 20;
  final List<Map<String, dynamic>> _posts = [];
  _FeedMode _mode = _FeedMode.latest;
  bool _loading = true, _loadingMore = false, _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<List<Map<String, dynamic>>> _fetchPage(int offset) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;
    var query = client.from('posts').select(
      'id,user_id,content,visibility,created_at,profiles!posts_user_id_fkey(id,username,display_name,avatar_url)',
    ).isFilter('deleted_at', null);

    if (_mode == _FeedMode.latest) {
      query = query.eq('visibility', 'public');
    } else {
      final followRows = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId)
          .eq('status', 'accepted');
      final authorIds = <String>{userId};
      for (final row in followRows) {
        final id = row['following_id'];
        if (id is String) authorIds.add(id);
      }
      query = query.inFilter('user_id', authorIds.toList());
    }

    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + _pageSize - 1);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _loadingMore = false;
      _hasMore = true;
      _error = null;
      _posts.clear();
    });
    try {
      final rows = await _fetchPage(0);
      if (!mounted) return;
      setState(() {
        _posts.addAll(rows);
        _hasMore = rows.length == _pageSize;
        _loading = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'feed_initial');
      if (mounted) setState(() { _error = AppErrorService.message(error); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _error != null) return;
    setState(() => _loadingMore = true);
    try {
      final rows = await _fetchPage(_posts.length);
      if (!mounted) return;
      final knownIds = _posts.map((p) => p['id']).toSet();
      final uniqueRows = rows.where((p) => !knownIds.contains(p['id']));
      setState(() {
        _posts.addAll(uniqueRows);
        _hasMore = rows.length == _pageSize;
        _loadingMore = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'feed_more');
      if (mounted) setState(() { _error = AppErrorService.message(error); _loadingMore = false; });
    }
  }

  Future<void> _refresh() => _loadFirstPage();

  void _changeMode(_FeedMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('NEXORA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
      actions: [
        IconButton(tooltip: 'القصص', onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StoriesScreen())), icon: const Icon(Icons.auto_awesome)),
        IconButton(tooltip: 'الإشعارات', onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NotificationsScreen())), icon: const Icon(Icons.notifications_none)),
        IconButton(tooltip: 'تحديث', onPressed: _refresh, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Row(children: [
          ChoiceChip(
            label: const Text('الأحدث'),
            selected: _mode == _FeedMode.latest,
            onSelected: (_) => _changeMode(_FeedMode.latest),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('المتابَعون'),
            selected: _mode == _FeedMode.following,
            onSelected: (_) => _changeMode(_FeedMode.following),
          ),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _posts.isEmpty
                ? AppErrorView(title: 'تعذر تحميل المنشورات', error: _error, onRetry: _loadFirstPage)
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(colors: [Color(0xFF171717), Color(0xFF050505)]),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('مساحتك. صوتك. عالمك.', style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold)),
                              SizedBox(height: 7),
                              Text('أفكارك تستحق مساحة أكبر.', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_posts.isEmpty)
                          _Empty(
                            icon: Icons.dynamic_feed,
                            title: _mode == _FeedMode.latest ? 'لسه مفيش منشورات عامة' : 'لسه مفيش منشورات من المتابَعين',
                            subtitle: _mode == _FeedMode.latest ? 'ابدأ أول حكاية في NEXORA.' : 'تابع أشخاص جدد عشان منشوراتهم تظهر هنا.',
                          )
                        else
                          for (final post in _posts) ...[
                            PostCard(post: post),
                            const SizedBox(height: 12),
                          ],
                        if (_error != null)
                          _Notice(text: _error!, error: true),
                        if (_loadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_hasMore)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: OutlinedButton.icon(
                              onPressed: _loadMore,
                              icon: const Icon(Icons.expand_more),
                              label: const Text('تحميل المزيد'),
                            ),
                          )
                        else if (_posts.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: Text('وصلت لآخر المنشورات', style: TextStyle(color: Color(0xFF8A8A8A)))),
                          ),
                      ],
                    ),
                  ),
      ),
    ]),
  );
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const int _pageSize = 30;
  final _search = TextEditingController();
  Timer? _debounce;
  late Future<List<Map<String, dynamic>>> _future;
  bool _hasMore = true;
  bool _searchPosts = false;
  bool _loadingMore = false;
  String _activeTerm = '';

  @override
  void initState() {
    super.initState();
    _future = _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  String _cleanTerm(String value) {
    return value
        .replaceAll(RegExp(r'[^#a-zA-Z0-9_ .\-\u0600-\u06FF]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<List<Map<String, dynamic>>> _load(
    String term, {
    int offset = 0,
  }) async {
    final client = Supabase.instance.client;
    final me = client.auth.currentUser!.id;
    late final List<Map<String, dynamic>> rows;
    if (_searchPosts && term.startsWith('#') && term.length > 1) {
      final tag = term.substring(1).toLowerCase();
      final matches = await client
          .from('post_hashtags')
          .select('posts!inner(id,user_id,content,visibility,created_at,profiles!posts_user_id_fkey(id,username,display_name,avatar_url)),hashtags!inner(tag)')
          .eq('hashtags.tag', tag)
          .eq('posts.visibility', 'public')
          .isFilter('posts.deleted_at', null)
          .order('created_at', referencedTable: 'posts', ascending: false)
          .order('id', referencedTable: 'posts', ascending: false)
          .range(offset, offset + _pageSize - 1);
      rows = matches
          .where((match) => match['posts'] is Map)
          .map((match) => Map<String, dynamic>.from(match['posts'] as Map))
          .toList(growable: false);
    } else if (_searchPosts) {
      final matches = await client
          .from('posts')
          .select('id,user_id,content,visibility,created_at,profiles!posts_user_id_fkey(id,username,display_name,avatar_url)')
          .eq('visibility', 'public')
          .isFilter('deleted_at', null)
          .ilike('content', '%${term.replaceAll('#', '')}%')
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(offset, offset + _pageSize - 1);
      rows = List<Map<String, dynamic>>.from(matches);
    } else {
      rows = await _loadPeople(client, me, term, offset);
    }
    if (mounted && offset == 0) {
      setState(() => _hasMore = rows.length == _pageSize);
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> _loadPeople(
    SupabaseClient client,
    String me,
    String term,
    int offset,
  ) async {
    var query = client
        .from('profiles')
        .select('id,username,display_name,bio,avatar_url,is_verified')
        .neq('id', me);
    if (term.isNotEmpty) {
      query = query.or('username.ilike.%$term%,display_name.ilike.%$term%');
    }
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + _pageSize - 1);
    return List<Map<String, dynamic>>.from(rows);
  }

  void _searchNow(String value) {
    _debounce?.cancel();
    final term = _cleanTerm(value);
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || term == _activeTerm) return;
      setState(() {
        _activeTerm = term;
        _hasMore = true;
        _loadingMore = false;
        _future = _load(term);
      });
    });
  }

  Future<void> _refresh() async {
    _debounce?.cancel();
    setState(() {
      _hasMore = true;
      _loadingMore = false;
      _future = _load(_activeTerm);
    });
    await _future;
  }

  Future<void> _loadMore(List<Map<String, dynamic>> current) async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final additions = await _load(_activeTerm, offset: current.length);
      if (!mounted) return;
      final known = current.map((person) => person['id']).toSet();
      final unique = additions.where((person) => !known.contains(person['id']));
      setState(() {
        _future = Future.value([...current, ...unique]);
        _hasMore = additions.length == _pageSize;
        _loadingMore = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'explore_load_more');
      if (mounted) {
        setState(() => _loadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            _searchPosts ? 'اكتشف المنشورات' : 'اكتشف الناس',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'المجتمعات',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CommunitiesScreen(),
                ),
              ),
              icon: const Icon(Icons.groups_outlined),
            ),
            IconButton(
              tooltip: 'طلبات الصداقة',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FriendRequestsScreen(),
                ),
              ),
              icon: const Icon(Icons.person_add_alt_1),
            ),
            IconButton(
              tooltip: 'الأصدقاء والمتابَعون',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FriendsScreen(),
                ),
              ),
              icon: const Icon(Icons.people_outline),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: _searchNow,
                onSubmitted: (value) {
                  _debounce?.cancel();
                  final term = _cleanTerm(value);
                  if (term != _activeTerm) {
                    setState(() {
                      _activeTerm = term;
                      _hasMore = true;
                      _loadingMore = false;
                      _future = _load(term);
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: _searchPosts ? 'ابحث في المنشورات أو اكتب #هاشتاج' : 'ابحث بالاسم أو اسم المستخدم',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'مسح البحث',
                          onPressed: () {
                            _search.clear();
                            _searchNow('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('الأشخاص'), icon: Icon(Icons.people_outline)),
                  ButtonSegment(value: true, label: Text('المنشورات'), icon: Icon(Icons.article_outlined)),
                ],
                selected: {_searchPosts},
                onSelectionChanged: (selection) {
                  setState(() {
                    _searchPosts = selection.first;
                    _hasMore = true;
                    _loadingMore = false;
                    _future = _load(_activeTerm);
                  });
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return AppErrorView(
                      title: _searchPosts ? 'تعذر تحميل المنشورات' : 'تعذر تحميل الأشخاص',
                      error: snapshot.error,
                      onRetry: _refresh,
                    );
                  }
                  final people = snapshot.data ?? [];
                  if (people.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          _Empty(
                            icon: Icons.travel_explore,
                            title: 'مفيش نتائج',
                            subtitle: _searchPosts ? 'جرّب كلمة أو هاشتاج مختلف.' : 'جرّب اسمًا أو username مختلفًا.',
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: people.length +
                          (_hasMore || _loadingMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        if (index == people.length) {
                          if (_loadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return Center(
                            child: TextButton.icon(
                              onPressed: () => _loadMore(people),
                              icon: const Icon(Icons.expand_more),
                              label: Text(_searchPosts ? 'تحميل منشورات أكثر' : 'تحميل أشخاص أكثر'),
                            ),
                          );
                        }
                        return _searchPosts
                            ? PostCard(post: people[index])
                            : PersonTile(profile: people[index], follow: true);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}
class _FriendsScreenState extends State<FriendsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() { super.initState(); _future = _load(); }
  Future<List<Map<String, dynamic>>> _load() async {
    final id = Supabase.instance.client.auth.currentUser!.id;
    final rows = await Supabase.instance.client.from('follows').select('status,profiles!follows_following_id_fkey(id,username,display_name,bio,avatar_url,is_verified)').eq('follower_id', id).eq('status', 'accepted').order('created_at', ascending: false).limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('مجتمعك', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: () => setState(() => _future = _load()), icon: const Icon(Icons.refresh))]), body: FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (context, snap) {
    if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    if (snap.hasError) return AppErrorView(title: 'تعذر تحميل المتابَعين', error: snap.error, onRetry: () => setState(() => _future = _load()));
    final rows = snap.data ?? [];
    if (rows.isEmpty) return const _Empty(icon: Icons.group_add, title: 'شبكتك لسه بتبدأ', subtitle: 'اكتشف أشخاص وتابعهم عشان يظهروا هنا.');
    return ListView.separated(padding: const EdgeInsets.all(16), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => rows[i]['profiles'] is Map<String, dynamic> ? PersonTile(profile: Map<String, dynamic>.from(rows[i]['profiles']), follow: false) : const SizedBox.shrink());
  }));
}

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key, required this.onPosted});
  final VoidCallback onPosted;
  @override
  State<CreateScreen> createState() => _CreateScreenState();
}
class _CreateScreenState extends State<CreateScreen> {
  final _text = TextEditingController();
  final _mediaService = MediaUploadService();
  final List<XFile> _media = [];
  String _visibility = 'public';
  bool _busy = false, _mediaBusy = false;
  String? _error;

  @override
  void dispose() { _text.dispose(); super.dispose(); }

  Future<void> _pickImages() async {
    setState(() { _mediaBusy = true; _error = null; });
    try {
      final files = await _mediaService.pickImages();
      if (!mounted || files.isEmpty) return;
      if (_media.length + files.length > MediaUploadService.maxFiles) {
        setState(() => _error = 'الحد الأقصى 10 ملفات في المنشور.');
      } else {
        setState(() => _media.addAll(files));
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'pick_images');
      if (mounted) setState(() => _error = AppErrorService.message(error));
    } finally {
      if (mounted) setState(() => _mediaBusy = false);
    }
  }

  Future<void> _pickVideo() async {
    if (_media.length >= MediaUploadService.maxFiles) {
      setState(() => _error = 'الحد الأقصى 10 ملفات في المنشور.');
      return;
    }
    setState(() { _mediaBusy = true; _error = null; });
    try {
      final file = await _mediaService.pickVideo();
      if (mounted && file != null) setState(() => _media.add(file));
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'pick_video');
      if (mounted) setState(() => _error = AppErrorService.message(error));
    } finally {
      if (mounted) setState(() => _mediaBusy = false);
    }
  }

  Future<void> _publish() async {
    final value = _text.text.trim();
    if ((value.isEmpty && _media.isEmpty) || value.length > 5000) {
      setState(() => _error = value.length > 5000 ? 'الحد الأقصى 5000 حرف.' : 'اكتب محتوى أو أضف صورة/فيديو.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;
    String? postId;
    List<String> uploadedPaths = [];
    try {
      final row = await client.from('posts').insert({
        'user_id': userId, 'content': value, 'visibility': 'private',
      }).select('id').single();
      postId = row['id'] as String;
      await HashtagService.indexPost(
        client: client,
        postId: postId,
        content: value,
      );
      if (_media.isNotEmpty) {
        uploadedPaths = await _mediaService.uploadPostMedia(
          userId: userId, postId: postId, files: List<XFile>.from(_media),
        );
      }
      await client.from('posts').update({'visibility': _visibility}).eq('id', postId);
      if (!mounted) return;
      _text.clear();
      setState(() => _media.clear());
      widget.onPosted();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر المنشور')));
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'publish');
      if (postId != null) {
        try { await _mediaService.removeUploaded(uploadedPaths); }
        catch (e, s) { AppErrorService.report(e, s, source: 'media_cleanup'); }
        try { await client.from('posts').delete().eq('id', postId); }
        catch (e, s) { AppErrorService.report(e, s, source: 'post_cleanup'); }
      }
      if (mounted) setState(() => _error = AppErrorService.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('إنشاء منشور', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('شارك لحظتك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          TextField(controller: _text, minLines: 5, maxLines: 12, maxLength: 5000,
            decoration: const InputDecoration(hintText: 'إيه اللي في بالك؟', border: InputBorder.none, filled: false)),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: _busy || _mediaBusy ? null : _pickImages,
              icon: const Icon(Icons.photo_library_outlined), label: const Text('صور')),
            OutlinedButton.icon(onPressed: _busy || _mediaBusy ? null : _pickVideo,
              icon: const Icon(Icons.video_library_outlined), label: const Text('فيديو')),
          ]),
          if (_mediaBusy) const LinearProgressIndicator(),
          if (_media.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (var i = 0; i < _media.length; i++)
              ListTile(
                dense: true, contentPadding: EdgeInsets.zero,
                leading: Icon(_media[i].name.toLowerCase().endsWith('.mp4') || _media[i].name.toLowerCase().endsWith('.webm')
                  ? Icons.video_file_outlined : Icons.image_outlined),
                title: Text(_media[i].name, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(tooltip: 'إزالة', onPressed: _busy ? null : () => setState(() => _media.removeAt(i)),
                  icon: const Icon(Icons.close)),
              ),
          ],
          DropdownButtonFormField<String>(
            value: _visibility, decoration: const InputDecoration(labelText: 'خصوصية المنشور'),
            items: const [
              DropdownMenuItem(value: 'public', child: Text('عام')),
              DropdownMenuItem(value: 'followers', child: Text('المتابعون')),
              DropdownMenuItem(value: 'private', child: Text('أنا فقط')),
            ],
            onChanged: _busy ? null : (v) => setState(() => _visibility = v ?? 'public'),
          ),
          if (_error != null) _Notice(text: _error!, error: true),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy || _mediaBusy ? null : _publish,
            icon: _busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
            label: Text(_busy ? 'جاري النشر والرفع...' : 'نشر المنشور'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ))),
      const SizedBox(height: 12),
      const Text('الملفات تُرفع إلى مساحة خاصة، ويُسمح بمشاهدتها حسب خصوصية المنشور والحساب.',
        style: TextStyle(color: Color(0xFFA1A1AA), height: 1.5)),
    ]),
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _future;
  late Future<List<Map<String, dynamic>>> _postsFuture;
  bool _postsHasMore = true;
  bool _postsLoadingMore = false;
  bool _profileImageBusy = false;
  final _profileMedia = MediaUploadService();
  static const int _profilePostPageSize = 50;
  @override
  void initState() {
    super.initState();
    _future = _load();
    _postsFuture = _loadOwnPosts();
  }
  Future<Map<String, dynamic>?> _load() async {
    final u = Supabase.instance.client.auth.currentUser!;
    return Supabase.instance.client.from('profiles').select().eq('id', u.id).maybeSingle();
  }
  Future<List<Map<String, dynamic>>> _loadOwnPosts({int offset = 0}) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;
    final rows = await client
        .from('posts')
        .select('id,user_id,content,visibility,created_at,profiles!posts_user_id_fkey(id,username,display_name,avatar_url)')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + _profilePostPageSize - 1);
    if (mounted) setState(() => _postsHasMore = rows.length == _profilePostPageSize);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _loadMoreOwnPosts(List<Map<String, dynamic>> current) async {
    if (_postsLoadingMore || !_postsHasMore) return;
    setState(() => _postsLoadingMore = true);
    try {
      final additions = await _loadOwnPosts(offset: current.length);
      if (!mounted) return;
      final known = current.map((post) => post['id']).toSet();
      final unique = additions.where((post) => !known.contains(post['id']));
      setState(() {
        _postsFuture = Future.value([...current, ...unique]);
        _postsLoadingMore = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'profile_posts_more');
      if (mounted) {
        setState(() => _postsLoadingMore = false);
        _toast(AppErrorService.message(error));
      }
    }
  }

  void _refreshOwnPosts() {
    setState(() {
      _postsHasMore = true;
      _postsLoadingMore = false;
      _postsFuture = _loadOwnPosts();
    });
  }
  Future<void> _uploadProfileImage(Map<String, dynamic> profile, String imageType) async {
    if (_profileImageBusy) return;
    setState(() => _profileImageBusy = true);
    String? uploadedPath;
    try {
      final file = await _profileMedia.pickProfileImage();
      if (file == null || !mounted) return;
      final userId = Supabase.instance.client.auth.currentUser!.id;
      uploadedPath = await _profileMedia.uploadProfileImage(
        userId: userId,
        file: file,
        imageType: imageType,
      );
      final column = imageType == 'avatar' ? 'avatar_url' : 'cover_url';
      final previous = (profile[column] ?? '').toString();
      final savedProfile = await Supabase.instance.client
          .from('profiles')
          .update({column: uploadedPath, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', userId)
          .select('id')
          .maybeSingle();
      if (savedProfile == null) {
        throw StateError('لم يتم حفظ صورة الملف الشخصي. تحقق من صلاحيات الحساب وحاول مرة أخرى.');
      }
      if (previous.startsWith('$userId/profile/')) {
        try { await _profileMedia.removeProfileImage(previous); } catch (error, stack) {
          AppErrorService.report(error, stack, source: 'remove_old_profile_image');
        }
      }
      if (mounted) {
        setState(() => _future = _load());
        _toast(imageType == 'avatar' ? 'تم تحديث الصورة الشخصية' : 'تم تحديث صورة الغلاف');
      }
    } catch (error, stack) {
      if (uploadedPath != null) {
        try { await _profileMedia.removeProfileImage(uploadedPath); } catch (_) {}
      }
      AppErrorService.report(error, stack, source: 'profile_image_upload');
      _toast(AppErrorService.message(error));
    } finally {
      if (mounted) setState(() => _profileImageBusy = false);
    }
  }

  void _toast(String v) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(v))); }
  Future<void> _edit(Map<String, dynamic> p) async {
    final name = TextEditingController(text: p['display_name'] as String? ?? '');
    final handle = TextEditingController(text: p['username'] as String? ?? '');
    final bio = TextEditingController(text: p['bio'] as String? ?? '');
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(title: const Text('تعديل الملف الشخصي'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم الظاهر')), const SizedBox(height: 10),
      TextField(controller: handle, decoration: const InputDecoration(labelText: 'اسم المستخدم')), const SizedBox(height: 10),
      TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'نبذة عنك')),
    ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ'))])));
    if (ok == true) {
      final h = handle.text.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
      if (name.text.trim().length < 2 || (h.isNotEmpty && !RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(h))) {
        _toast('راجع الاسم واسم المستخدم (3–24 حرف إنجليزي أو رقم أو _)');
      } else {
        try {
          await Supabase.instance.client.from('profiles').update({'display_name': name.text.trim(), 'username': h.isEmpty ? null : h, 'bio': bio.text.trim()}).eq('id', Supabase.instance.client.auth.currentUser!.id);
          if (mounted) setState(() => _future = _load());
        } catch (e, s) { AppErrorService.report(e, s, source: 'profile_update'); _toast(AppErrorService.message(e)); }
      }
    }
    name.dispose(); handle.dispose(); bio.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('ملفي الشخصي', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(tooltip: 'مركز الخصوصية', onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PrivacySettingsScreen())), icon: const Icon(Icons.shield_outlined)), IconButton(tooltip: 'تسجيل الخروج', onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout))]), body: FutureBuilder<Map<String, dynamic>?>(future: _future, builder: (context, snap) {
    if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    if (snap.hasError) return AppErrorView(title: 'تعذر تحميل حسابك', error: snap.error, onRetry: () => setState(() => _future = _load()));
    final p = snap.data;
    if (p == null) return const _Empty(icon: Icons.person_off, title: 'الملف الشخصي غير موجود', subtitle: 'راجع إعداد إنشاء صف profiles عند تسجيل الحساب.');
    final u = Supabase.instance.client.auth.currentUser!;
    return ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.fromLTRB(16, 12, 16, 22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: [Color(0xFF171717), Color(0xFF050505)]), border: Border.all(color: const Color(0xFF292929))), child: Column(children: [
        Stack(children: [
          _ProfileCover(path: p['cover_url']?.toString()),
          Positioned(left: 8, top: 8, child: IconButton.filledTonal(
            tooltip: 'تغيير صورة الغلاف',
            onPressed: _profileImageBusy ? null : () => _uploadProfileImage(p, 'cover'),
            icon: const Icon(Icons.photo_camera_outlined),
          )),
        ]),
        const SizedBox(height: 8),
        Stack(alignment: Alignment.bottomRight, children: [
          _ProfileAvatar(url: p['avatar_url']?.toString(), size: 88),
          IconButton.filledTonal(
            tooltip: 'تغيير الصورة الشخصية',
            onPressed: _profileImageBusy ? null : () => _uploadProfileImage(p, 'avatar'),
            icon: const Icon(Icons.camera_alt, size: 17),
          ),
        ]),
        if (_profileImageBusy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
        const SizedBox(height: 14),
        Text((p['display_name'] ?? 'مستخدم NEXORA').toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        Text('@' + (p['username'] ?? 'user').toString(), style: const TextStyle(color: Color(0xFFFFFFFF))),
        if ((p['bio'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(p['bio'].toString(), textAlign: TextAlign.center)),
        const SizedBox(height: 14), OutlinedButton.icon(onPressed: () => _edit(p), icon: const Icon(Icons.edit), label: const Text('تعديل الملف الشخصي')),
      ])),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SavedPostsScreen())),
        icon: const Icon(Icons.bookmarks_outlined),
        label: const Text('المنشورات المحفوظة'),
      ),
      const SizedBox(height: 14), _Info(icon: Icons.mail_outline, title: 'البريد الإلكتروني', value: u.email ?? 'غير متاح'),
      const SizedBox(height: 10), _Info(icon: Icons.shield_outlined, title: 'الخصوصية', value: (p['is_private'] as bool? ?? false) ? 'حساب خاص' : 'حساب عام'),
      const SizedBox(height: 10), _Info(icon: Icons.verified_outlined, title: 'التوثيق', value: (p['is_verified'] as bool? ?? false) ? 'موثّق' : 'غير موثّق'),
      const SizedBox(height: 22),
      Row(
        children: [
          const Expanded(child: Text('منشوراتي', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
          IconButton(
            tooltip: 'تحديث المنشورات',
            onPressed: _refreshOwnPosts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _postsFuture,
        builder: (context, postsSnapshot) {
          if (postsSnapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (postsSnapshot.hasError) {
            return AppErrorView(
              title: 'تعذر تحميل منشوراتك',
              error: postsSnapshot.error,
              onRetry: _refreshOwnPosts,
            );
          }
          final posts = postsSnapshot.data ?? const <Map<String, dynamic>>[];
          if (posts.isEmpty) {
            return const _Empty(
              icon: Icons.post_add,
              title: 'لسه ما نشرتش حاجة',
              subtitle: 'أول منشور ليك هيظهر هنا.',
            );
          }
          return Column(
            children: [
              for (final post in posts) ...[
                PostCard(post: post),
                const SizedBox(height: 10),
              ],
              if (_postsLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_postsHasMore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => _loadMoreOwnPosts(posts),
                    icon: const Icon(Icons.expand_more),
                    label: const Text('تحميل منشورات أقدم'),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 20), OutlinedButton.icon(onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
    ]);
  }));
}

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = Supabase.instance.client;
    final rows = await client
        .from('saves')
        .select(
          'created_at,posts!saves_post_id_fkey(id,user_id,content,visibility,created_at,profiles!posts_user_id_fkey(id,username,display_name,avatar_url))',
        )
        .eq('user_id', client.auth.currentUser!.id)
        .order('created_at', ascending: false);
    final posts = <Map<String, dynamic>>[];
    for (final row in rows) {
      final post = row['posts'];
      if (post is Map) posts.add(Map<String, dynamic>.from(post));
    }
    return posts;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('المنشورات المحفوظة')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return AppErrorView(
                title: 'تعذر تحميل المحفوظات',
                error: snapshot.error,
                onRetry: _refresh,
              );
            }
            final posts = snapshot.data ?? const <Map<String, dynamic>>[];
            if (posts.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    _Empty(
                      icon: Icons.bookmark_border,
                      title: 'مفيش منشورات محفوظة',
                      subtitle: 'احفظ أي منشور من علامة الحفظ عشان ترجع له هنا.',
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => PostCard(post: posts[index]),
              ),
            );
          },
        ),
      );
}

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post});
  final Map<String, dynamic> post;
  @override
  State<PostCard> createState() => _PostCardState();
}
class _PostCardState extends State<PostCard> {
  bool? _liked;
  bool _busy = true;
  bool _reposted = false;
  String? _repostId;
  bool _repostBusy = false;
  bool _saved = false;
  bool _saveBusy = false;

  @override
  void initState() {
    super.initState();
    _loadLikeState();
    _loadRepostState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final row = await Supabase.instance.client
          .from('saves')
          .select('post_id')
          .eq('user_id', uid)
          .eq('post_id', widget.post['id'] as String)
          .maybeSingle();
      if (mounted) setState(() => _saved = row != null);
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'load_saved_state');
    }
  }

  Future<void> _toggleSave() async {
    if (_saveBusy) return;
    setState(() => _saveBusy = true);
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser!.id;
    final postId = widget.post['id'] as String;
    try {
      if (_saved) {
        await db.from('saves').delete().eq('user_id', uid).eq('post_id', postId);
        if (mounted) setState(() => _saved = false);
      } else {
        await db.from('saves').insert({'user_id': uid, 'post_id': postId});
        if (mounted) setState(() => _saved = true);
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'toggle_save');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saveBusy = false);
    }
  }

  Future<void> _loadRepostState() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final row = await Supabase.instance.client
          .from('reposts')
          .select('id')
          .eq('user_id', uid)
          .eq('post_id', widget.post['id'] as String)
          .limit(1)
          .maybeSingle();
      if (mounted) setState(() {
        _reposted = row != null;
        _repostId = row?['id'] as String?;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'load_repost_state');
    }
  }

  Future<void> _toggleRepost() async {
    if (_repostBusy || widget.post['visibility'] != 'public') return;
    setState(() => _repostBusy = true);
    final db = Supabase.instance.client;
    try {
      if (_reposted && _repostId != null) {
        await db.from('reposts').delete().eq('id', _repostId!);
        if (mounted) setState(() { _reposted = false; _repostId = null; });
      } else {
        final uid = db.auth.currentUser!.id;
        final row = await db.from('reposts').insert({
          'user_id': uid,
          'post_id': widget.post['id'] as String,
        }).select('id').single();
        if (mounted) setState(() {
          _reposted = true;
          _repostId = row['id'] as String;
        });
      }
    } catch (error, stack) {
      if (error is PostgrestException && error.code == '23505') {
        try {
          final uid = db.auth.currentUser!.id;
          final existing = await db.from('reposts')
              .select('id')
              .eq('user_id', uid)
              .eq('post_id', widget.post['id'] as String)
              .limit(1)
              .maybeSingle();
          if (mounted && existing != null) {
            setState(() {
              _reposted = true;
              _repostId = existing['id'] as String;
            });
          }
        } catch (reloadError, reloadStack) {
          AppErrorService.report(reloadError, reloadStack, source: 'repost_conflict_reload');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppErrorService.message(reloadError))),
            );
          }
        }
      } else {
        AppErrorService.report(error, stack, source: 'repost');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppErrorService.message(error))),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _repostBusy = false);
    }
  }

  Future<void> _loadLikeState() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final row = await Supabase.instance.client
          .from('likes')
          .select('post_id')
          .eq('user_id', uid)
          .eq('post_id', widget.post['id'] as String)
          .maybeSingle();
      if (mounted) setState(() { _liked = row != null; _busy = false; });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'load_like_state');
      if (mounted) setState(() { _liked = false; _busy = false; });
    }
  }

  Future<void> _like() async {
    if (_busy || _liked == null) return;
    setState(() => _busy = true);
    final db = Supabase.instance.client, uid = Supabase.instance.client.auth.currentUser!.id, pid = widget.post['id'] as String;
    try {
      if (_liked == false) { await db.from('likes').insert({'user_id': uid, 'post_id': pid}); if (mounted) setState(() => _liked = true); }
      else { await db.from('likes').delete().eq('user_id', uid).eq('post_id', pid); if (mounted) setState(() => _liked = false); }
    } catch (e, s) { AppErrorService.report(e, s, source: 'like'); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorService.message(e)))); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final a = widget.post['profiles'];
    final name = a is Map ? (a['display_name'] ?? 'مستخدم NEXORA').toString() : 'مستخدم NEXORA';
    final handle = a is Map ? (a['username'] ?? 'user').toString() : 'user';
    final d = DateTime.tryParse((widget.post['created_at'] ?? '').toString())?.toLocal();
    final stamp = d == null ? '' : d.day.toString() + '/' + d.month.toString() + ' • ' + d.hour.toString().padLeft(2, '0') + ':' + d.minute.toString().padLeft(2, '0');
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [_ProfileAvatar(url: a is Map ? a['avatar_url']?.toString() : null), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w800)), Text('@' + handle + ' • ' + stamp, style: const TextStyle(fontSize: 11, color: Color(0xFF8390A4)))])), const Icon(Icons.more_horiz)]),
      if ((widget.post['content'] ?? '').toString().isNotEmpty)
        Text((widget.post['content'] ?? '').toString(), style: const TextStyle(fontSize: 15, height: 1.65)),
      PostMediaGallery(postId: widget.post['id'] as String),
      const Divider(height: 24, color: Color(0xFF292929)),
      Row(children: [
        TextButton.icon(
          onPressed: _busy || _liked == null ? null : _like,
          icon: Icon(_liked == true ? Icons.favorite : Icons.favorite_border),
          label: Text(_busy && _liked == null ? '...' : (_liked == true ? 'أعجبك' : 'إعجاب')),
        ),
        TextButton.icon(
          onPressed: widget.post['visibility'] == 'public' && !_repostBusy ? _toggleRepost : null,
          icon: _repostBusy
              ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(_reposted ? Icons.repeat_on : Icons.repeat, color: _reposted ? const Color(0xFFB8E986) : null),
          label: Text(_reposted ? 'أعدت النشر' : 'إعادة نشر'),
        ),
        IconButton(
          tooltip: _saved ? 'إزالة من المحفوظات' : 'حفظ المنشور',
          onPressed: _saveBusy ? null : _toggleSave,
          icon: _saveBusy
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => CommentsScreen(postId: widget.post['id'] as String),
          )),
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('تعليق'),
        ),
      ]),
    ])));
  }
}

class PersonTile extends StatefulWidget {
  const PersonTile({super.key, required this.profile, required this.follow});
  final Map<String, dynamic> profile;
  final bool follow;
  @override
  State<PersonTile> createState() => _PersonTileState();
}
class _PersonTileState extends State<PersonTile> {
  String? _followStatus;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    if (widget.follow) _loadFollowStatus();
    else _busy = false;
  }

  Future<void> _loadFollowStatus() async {
    try {
      final me = Supabase.instance.client.auth.currentUser!.id;
      final row = await Supabase.instance.client
          .from('follows')
          .select('status')
          .eq('follower_id', me)
          .eq('following_id', widget.profile['id'] as String)
          .maybeSingle();
      if (mounted) setState(() { _followStatus = row?['status'] as String?; _busy = false; });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'load_follow_status');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    final other = widget.profile['id'] as String;
    try {
      if (_followStatus == null) {
        final status = await Supabase.instance.client.rpc(
          'request_follow',
          params: {'p_target_user_id': other},
        );
        if (mounted) setState(() => _followStatus = status.toString());
      } else {
        await Supabase.instance.client.rpc(
          'cancel_follow',
          params: {'p_target_user_id': other},
        );
        if (mounted) setState(() => _followStatus = null);
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'follow');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Card(child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [
      _ProfileAvatar(url: p['avatar_url']?.toString(), size: 48), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Flexible(child: Text((p['display_name'] ?? 'مستخدم').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))), if (p['is_verified'] == true) const Icon(Icons.verified, size: 16, color: Colors.lightBlueAccent)]),
        Text('@' + (p['username'] ?? 'user').toString(), style: const TextStyle(color: Color(0xFF9AA7BA), fontSize: 12)),
        if ((p['bio'] ?? '').toString().isNotEmpty) Text(p['bio'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF8996AA), fontSize: 12)),
      ])),
      FriendRequestAction(otherUserId: p['id'] as String),
      if (widget.follow) OutlinedButton(onPressed: _busy ? null : _toggle, child: _busy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_followStatus == 'pending' ? 'إلغاء الطلب' : (_followStatus == 'accepted' ? 'إلغاء المتابعة' : 'متابعة'))),
    ])));
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.size = 46});
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * .3), gradient: const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFC0C0C0)]), boxShadow: const [BoxShadow(color: Color(0x33FFFFFF), blurRadius: 20, offset: Offset(0, 7))]), child: Icon(Icons.bolt, color: const Color(0xFF000000), size: size * .58));
}
Future<String?> _resolvePrivateMediaUrl(String? value) async {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;
  final parsed = Uri.tryParse(raw);
  if (parsed != null && (parsed.scheme == 'https' || parsed.scheme == 'http') && parsed.host.isNotEmpty) {
    return raw;
  }
  try {
    return await Supabase.instance.client.storage.from('nexora-media').createSignedUrl(raw, 3600);
  } catch (error, stack) {
    AppErrorService.report(error, stack, source: 'resolve_profile_media');
    return null;
  }
}

class _ProfileAvatar extends StatefulWidget {
  const _ProfileAvatar({this.url, this.size = 44});
  final String? url;
  final double size;
  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  late Future<String?> _urlFuture;
  @override
  void initState() { super.initState(); _urlFuture = _resolvePrivateMediaUrl(widget.url); }
  @override
  void didUpdateWidget(covariant _ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _urlFuture = _resolvePrivateMediaUrl(widget.url);
  }
  @override
  Widget build(BuildContext context) => Container(
    width: widget.size, height: widget.size, clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF243448), border: Border.all(color: const Color(0xFF40536A))),
    child: FutureBuilder<String?>(
      future: _urlFuture,
      builder: (context, snapshot) => snapshot.data == null
        ? Icon(Icons.person, size: widget.size * .58, color: Colors.white)
        : Image.network(snapshot.data!, width: widget.size, height: widget.size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(Icons.person, size: widget.size * .58, color: Colors.white)),
    ),
  );
}

class _ProfileCover extends StatefulWidget {
  const _ProfileCover({this.path});
  final String? path;
  @override
  State<_ProfileCover> createState() => _ProfileCoverState();
}

class _ProfileCoverState extends State<_ProfileCover> {
  late Future<String?> _urlFuture;
  @override
  void initState() { super.initState(); _urlFuture = _resolvePrivateMediaUrl(widget.path); }
  @override
  void didUpdateWidget(covariant _ProfileCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _urlFuture = _resolvePrivateMediaUrl(widget.path);
  }
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(
      height: 124, width: double.infinity,
      child: FutureBuilder<String?>(
        future: _urlFuture,
        builder: (context, snapshot) => snapshot.data == null
          ? Container(color: const Color(0xFF202A36), child: const Center(child: Icon(Icons.landscape_outlined, size: 38, color: Color(0xFF8492A6))))
          : Image.network(snapshot.data!, fit: BoxFit.cover, width: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF202A36), child: const Icon(Icons.broken_image_outlined))),
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.title, required this.value});
  final IconData icon; final String title, value;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: const Color(0xFFFFFFFF)), title: Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF8F9CB0))), subtitle: Text(value)));
}
class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.error});
  final String text; final bool error;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: error ? const Color(0x33FF7777) : const Color(0x333E7540), borderRadius: BorderRadius.circular(14)), child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: error ? const Color(0xFFFFA0A0) : const Color(0xFFFFFFFF))));
}
class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.subtitle});
  final IconData icon; final String title, subtitle;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 54, color: const Color(0xFFFFFFFF)), const SizedBox(height: 18), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8E9BB0), height: 1.6))])));
}
