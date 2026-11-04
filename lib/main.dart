import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_error.dart';

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
    theme: ThemeData(
      useMaterial3: true, brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF080B12),
      colorScheme: const ColorScheme.dark(primary: Color(0xFFB8F36B), onPrimary: Color(0xFF10160A), secondary: Color(0xFF8FA5C7), surface: Color(0xFF111827)),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF080B12), surfaceTintColor: Colors.transparent),
      cardTheme: CardThemeData(color: const Color(0xFF111827), elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFF202A3B)))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF111827), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF263247))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF263247)))),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: Color(0xFF0D1320), indicatorColor: Color(0xFF283A24)),
    ),
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
                      style: const TextStyle(color: Color(0xFF9BA8BC))),
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
                      validator: (v) => v == null || !RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$').hasMatch(v.trim()) ? 'اكتب بريد إلكتروني صحيح' : null,
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
    final pages = <Widget>[HomeScreen(key: ValueKey(_feedVersion)), const ExploreScreen(), CreateScreen(onPosted: _posted), const FriendsScreen(), const ProfileScreen()];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(selectedIndex: _tab, onDestinationSelected: (v) => setState(() => _tab = v), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'استكشاف'),
        NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'إنشاء'),
        NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'الأصدقاء'),
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
class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() { super.initState(); _future = _load(); }
  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await Supabase.instance.client.from('posts').select('id,user_id,content,visibility,created_at,profiles!posts_user_id_fkey(id,username,display_name,avatar_url)').eq('visibility', 'public').order('created_at', ascending: false).limit(40);
    return List<Map<String, dynamic>>.from(rows);
  }
  Future<void> _refresh() async { setState(() => _future = _load()); await _future; }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('NEXORA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))]),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return AppErrorView(title: 'تعذر تحميل المنشورات', error: snap.error, onRetry: () => setState(() => _future = _load()));
      final posts = snap.data ?? [];
      if (posts.isEmpty) return RefreshIndicator(onRefresh: _refresh, child: ListView(children: const [SizedBox(height: 80), _Empty(icon: Icons.dynamic_feed, title: 'لسه مفيش منشورات', subtitle: 'ابدأ أول حكاية في NEXORA أو تابع أشخاص جدد.')]));
      return RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF344B2C), Color(0xFF18283A)])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('مساحتك. صوتك. عالمك.', style: TextStyle(color: Color(0xFFB8F36B), fontWeight: FontWeight.bold)), SizedBox(height: 7), Text('أفكارك تستحق مساحة أكبر.', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900))])),
        const SizedBox(height: 16), for (final p in posts) ...[PostCard(post: p), const SizedBox(height: 12)],
      ]));
    }),
  );
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}
class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() { super.initState(); _future = _load(''); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  Future<List<Map<String, dynamic>>> _load(String term) async {
    final me = Supabase.instance.client.auth.currentUser!.id;
    var q = Supabase.instance.client.from('profiles').select('id,username,display_name,bio,avatar_url,is_verified').neq('id', me);
    if (term.trim().isNotEmpty) { final s = term.trim().replaceAll(',', ' '); q = q.or('username.ilike.%' + s + '%,display_name.ilike.%' + s + '%'); }
    return List<Map<String, dynamic>>.from(await q.order('created_at', ascending: false).limit(50));
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('اكتشف الناس', style: TextStyle(fontWeight: FontWeight.w800))), body: Column(children: [
    Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _search, onSubmitted: (v) => setState(() => _future = _load(v)), decoration: InputDecoration(hintText: 'اسم أو username', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: () => setState(() => _future = _load(_search.text)), icon: const Icon(Icons.arrow_forward))))),
    Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return AppErrorView(title: 'تعذر تحميل الأشخاص', error: snap.error, onRetry: () => setState(() => _future = _load(_search.text)));
      final people = snap.data ?? [];
      if (people.isEmpty) return const _Empty(icon: Icons.travel_explore, title: 'مفيش نتائج', subtitle: 'جرّب كلمة بحث مختلفة.');
      return ListView.separated(padding: const EdgeInsets.all(16), itemCount: people.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => PersonTile(profile: people[i], follow: true));
    })),
  ]));
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
  String _visibility = 'public';
  bool _busy = false;
  String? _error;
  @override
  void dispose() { _text.dispose(); super.dispose(); }
  Future<void> _publish() async {
    final value = _text.text.trim();
    if (value.isEmpty || value.length > 5000) { setState(() => _error = value.isEmpty ? 'اكتب محتوى المنشور الأول.' : 'الحد الأقصى 5000 حرف.'); return; }
    setState(() { _busy = true; _error = null; });
    try {
      await Supabase.instance.client.from('posts').insert({'user_id': Supabase.instance.client.auth.currentUser!.id, 'content': value, 'visibility': _visibility});
      if (!mounted) return;
      _text.clear(); widget.onPosted();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر المنشور')));
    } catch (e, s) { AppErrorService.report(e, s, source: 'publish'); if (mounted) setState(() => _error = AppErrorService.message(e)); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('إنشاء منشور', style: TextStyle(fontWeight: FontWeight.w800))), body: ListView(padding: const EdgeInsets.all(18), children: [
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('شارك لحظتك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 16),
      TextField(controller: _text, minLines: 7, maxLines: 14, maxLength: 5000, decoration: const InputDecoration(hintText: 'إيه اللي في بالك؟', border: InputBorder.none, filled: false)),
      DropdownButtonFormField<String>(value: _visibility, decoration: const InputDecoration(labelText: 'خصوصية المنشور'), items: const [DropdownMenuItem(value: 'public', child: Text('عام')), DropdownMenuItem(value: 'followers', child: Text('المتابعون')), DropdownMenuItem(value: 'private', child: Text('أنا فقط'))], onChanged: _busy ? null : (v) => setState(() => _visibility = v ?? 'public')),
      if (_error != null) _Notice(text: _error!, error: true), const SizedBox(height: 16),
      FilledButton.icon(onPressed: _busy ? null : _publish, icon: _busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send), label: const Text('نشر المنشور'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
    ]))),
    const SizedBox(height: 12), const Text('رفع الصور والفيديو والمحادثات الخاصة غير مفعّل في النسخة دي؛ محتاجين تجهيز Storage وجداول وسياسات آمنة قبل تفعيله.', style: TextStyle(color: Color(0xFF8996AA), height: 1.5)),
  ]));
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _future;
  @override
  void initState() { super.initState(); _future = _load(); }
  Future<Map<String, dynamic>?> _load() async {
    final u = Supabase.instance.client.auth.currentUser!;
    return Supabase.instance.client.from('profiles').select().eq('id', u.id).maybeSingle();
  }
  void _toast(String v) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(v))); }
  Future<void> _edit(Map<String, dynamic> p) async {
    final name = TextEditingController(text: p['display_name'] as String? ?? '');
    final handle = TextEditingController(text: p['username'] as String? ?? '');
    final bio = TextEditingController(text: p['bio'] as String? ?? '');
    var private = p['is_private'] as bool? ?? false;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(title: const Text('تعديل الملف الشخصي'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم الظاهر')), const SizedBox(height: 10),
      TextField(controller: handle, decoration: const InputDecoration(labelText: 'اسم المستخدم')), const SizedBox(height: 10),
      TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'نبذة عنك')),
      SwitchListTile(value: private, onChanged: (v) => setD(() => private = v), title: const Text('حساب خاص')),
    ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ'))])));
    if (ok == true) {
      final h = handle.text.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
      if (name.text.trim().length < 2 || (h.isNotEmpty && !RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(h))) {
        _toast('راجع الاسم واسم المستخدم (3–24 حرف إنجليزي أو رقم أو _)');
      } else {
        try {
          await Supabase.instance.client.from('profiles').update({'display_name': name.text.trim(), 'username': h.isEmpty ? null : h, 'bio': bio.text.trim(), 'is_private': private}).eq('id', Supabase.instance.client.auth.currentUser!.id);
          if (mounted) setState(() => _future = _load());
        } catch (e, s) { AppErrorService.report(e, s, source: 'profile_update'); _toast(AppErrorService.message(e)); }
      }
    }
    name.dispose(); handle.dispose(); bio.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('ملفي الشخصي', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(tooltip: 'تسجيل الخروج', onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout))]), body: FutureBuilder<Map<String, dynamic>?>(future: _future, builder: (context, snap) {
    if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    if (snap.hasError) return AppErrorView(title: 'تعذر تحميل حسابك', error: snap.error, onRetry: () => setState(() => _future = _load()));
    final p = snap.data;
    if (p == null) return const _Empty(icon: Icons.person_off, title: 'الملف الشخصي غير موجود', subtitle: 'راجع إعداد إنشاء صف profiles عند تسجيل الحساب.');
    final u = Supabase.instance.client.auth.currentUser!;
    return ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: [Color(0xFF263A2A), Color(0xFF121C2B)]), border: Border.all(color: const Color(0xFF344536))), child: Column(children: [
        const _Brand(size: 72), const SizedBox(height: 14),
        Text((p['display_name'] ?? 'مستخدم NEXORA').toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        Text('@' + (p['username'] ?? 'user').toString(), style: const TextStyle(color: Color(0xFFB8F36B))),
        if ((p['bio'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(p['bio'].toString(), textAlign: TextAlign.center)),
        const SizedBox(height: 14), OutlinedButton.icon(onPressed: () => _edit(p), icon: const Icon(Icons.edit), label: const Text('تعديل الملف الشخصي')),
      ])),
      const SizedBox(height: 14), _Info(icon: Icons.mail_outline, title: 'البريد الإلكتروني', value: u.email ?? 'غير متاح'),
      const SizedBox(height: 10), _Info(icon: Icons.shield_outlined, title: 'الخصوصية', value: (p['is_private'] as bool? ?? false) ? 'حساب خاص' : 'حساب عام'),
      const SizedBox(height: 10), _Info(icon: Icons.verified_outlined, title: 'التوثيق', value: (p['is_verified'] as bool? ?? false) ? 'موثّق' : 'غير موثّق'),
      const SizedBox(height: 20), OutlinedButton.icon(onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
    ]);
  }));
}

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post});
  final Map<String, dynamic> post;
  @override
  State<PostCard> createState() => _PostCardState();
}
class _PostCardState extends State<PostCard> {
  bool _liked = false, _busy = false;
  Future<void> _like() async {
    if (_busy) return;
    setState(() => _busy = true);
    final db = Supabase.instance.client, uid = Supabase.instance.client.auth.currentUser!.id, pid = widget.post['id'] as String;
    try {
      final row = await db.from('likes').select('post_id').eq('user_id', uid).eq('post_id', pid).maybeSingle();
      if (row == null) { await db.from('likes').insert({'user_id': uid, 'post_id': pid}); if (mounted) setState(() => _liked = true); }
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
      Row(children: [const _Avatar(), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w800)), Text('@' + handle + ' • ' + stamp, style: const TextStyle(fontSize: 11, color: Color(0xFF8390A4)))])), const Icon(Icons.more_horiz)]),
      const SizedBox(height: 14), Text((widget.post['content'] ?? '').toString(), style: const TextStyle(fontSize: 15, height: 1.65)),
      const Divider(height: 24, color: Color(0xFF263247)),
      Row(children: [TextButton.icon(onPressed: _busy ? null : _like, icon: Icon(_liked ? Icons.favorite : Icons.favorite_border, color: _liked ? Colors.pinkAccent : null), label: Text(_liked ? 'أعجبك' : 'إعجاب')), const Spacer(), const Icon(Icons.chat_bubble_outline, size: 18), const SizedBox(width: 6), const Text('تعليق')]),
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
  bool _following = false, _busy = false;
  Future<void> _toggle() async {
    setState(() => _busy = true);
    final db = Supabase.instance.client, me = Supabase.instance.client.auth.currentUser!.id, other = widget.profile['id'] as String;
    try {
      if (_following) { await db.from('follows').delete().eq('follower_id', me).eq('following_id', other); if (mounted) setState(() => _following = false); }
      else { await db.from('follows').insert({'follower_id': me, 'following_id': other, 'status': 'accepted'}); if (mounted) setState(() => _following = true); }
    } catch (e, s) { AppErrorService.report(e, s, source: 'follow'); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorService.message(e)))); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Card(child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [
      const _Avatar(size: 48), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Flexible(child: Text((p['display_name'] ?? 'مستخدم').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))), if (p['is_verified'] == true) const Icon(Icons.verified, size: 16, color: Colors.lightBlueAccent)]),
        Text('@' + (p['username'] ?? 'user').toString(), style: const TextStyle(color: Color(0xFF9AA7BA), fontSize: 12)),
        if ((p['bio'] ?? '').toString().isNotEmpty) Text(p['bio'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF8996AA), fontSize: 12)),
      ])),
      if (widget.follow) OutlinedButton(onPressed: _busy ? null : _toggle, child: _busy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_following ? 'تتابعه' : 'متابعة')),
    ])));
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.size = 46});
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * .3), gradient: const LinearGradient(colors: [Color(0xFFB8F36B), Color(0xFF3E7540)]), boxShadow: const [BoxShadow(color: Color(0x333F743E), blurRadius: 20, offset: Offset(0, 7))]), child: Icon(Icons.bolt, color: const Color(0xFF10160A), size: size * .58));
}
class _Avatar extends StatelessWidget {
  const _Avatar({this.size = 44});
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF243448), border: Border.all(color: const Color(0xFF40536A))), child: Icon(Icons.person, size: size * .58, color: const Color(0xFFB8F36B)));
}
class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.title, required this.value});
  final IconData icon; final String title, value;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: const Color(0xFFB8F36B)), title: Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF8F9CB0))), subtitle: Text(value)));
}
class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.error});
  final String text; final bool error;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: error ? const Color(0x33FF7777) : const Color(0x333E7540), borderRadius: BorderRadius.circular(14)), child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: error ? const Color(0xFFFFA0A0) : const Color(0xFFB8F36B))));
}
class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.subtitle});
  final IconData icon; final String title, subtitle;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 54, color: const Color(0xFFB8F36B)), const SizedBox(height: 18), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8E9BB0), height: 1.6))])));
}
