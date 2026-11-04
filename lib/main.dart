import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _urlInput = String.fromEnvironment('SUPABASE_URL');
final _url = _urlInput.trim();
const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configured = _url.startsWith('https://') && _anonKey.isNotEmpty;
  if (configured) {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }
  runApp(NexoraApp(isConfigured: configured));
}

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key, required this.isConfigured});
  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF08090D);
    return MaterialApp(
      title: 'NEXORA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE8EAF0),
          secondary: Color(0xFF9CA3AF),
          surface: Color(0xFF14161D),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF14161D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: isConfigured ? const AuthGate() : const SetupScreen(),
      ),
    );
  }
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BrandMark(),
                const SizedBox(height: 24),
                const Text('NEXORA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 3)),
                const SizedBox(height: 12),
                const Text('التطبيق جاهز للاتصال بقاعدة البيانات', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                const Text('أضف SUPABASE_URL و SUPABASE_ANON_KEY كمتغيرات بناء آمنة في GitHub Actions. لا تضع مفتاح service_role داخل التطبيق أبداً.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9CA3AF), height: 1.6)),
              ],
            ),
          ),
        ),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        return session == null ? const AuthScreen() : const ProfileScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = true;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _message = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (_register) {
        final result = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'display_name': _name.text.trim()},
        );
        if (result.session == null && mounted) {
          setState(() => _message = 'تم إنشاء الطلب. راجع بريدك الإلكتروني لتأكيد الحساب ثم سجّل الدخول.');
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'حصل خطأ غير متوقع. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: _BrandMark()),
                      const SizedBox(height: 20),
                      const Text('NEXORA', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 3)),
                      const SizedBox(height: 8),
                      Text(_register ? 'ابدأ عالمك الخاص' : 'أهلاً بعودتك', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB7BBC6), fontSize: 17)),
                      const SizedBox(height: 30),
                      if (_register) ...[
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'الاسم الظاهر', prefixIcon: Icon(Icons.person_outline)),
                          validator: (v) => _register && (v == null || v.trim().length < 2) ? 'اكتب اسمك (حرفين على الأقل)' : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.mail_outline)),
                        validator: (v) => v == null || !v.contains('@') ? 'اكتب بريد إلكتروني صحيح' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock_outline)),
                        validator: (v) => v == null || v.length < 8 ? 'كلمة المرور 8 أحرف على الأقل' : null,
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 14),
                        Text(_message!, style: const TextStyle(color: Color(0xFFFFB4AB)), textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: _busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_register ? 'إنشاء حساب' : 'تسجيل الدخول', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: _busy ? null : () => setState(() { _register = !_register; _message = null; }),
                        child: Text(_register ? 'عندك حساب؟ سجّل الدخول' : 'لسه جديد؟ أنشئ حساب'),
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;

  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser!;
    return Supabase.instance.client.from('profiles').select().eq('id', user.id).maybeSingle();
  }

  Future<void> _editProfile(Map<String, dynamic> profile) async {
    final name = TextEditingController(text: profile['display_name'] as String? ?? '');
    final username = TextEditingController(text: profile['username'] as String? ?? '');
    final bio = TextEditingController(text: profile['bio'] as String? ?? '');
    var isPrivate = profile['is_private'] as bool? ?? false;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل الملف الشخصي'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم الظاهر')),
                const SizedBox(height: 10),
                TextField(controller: username, decoration: const InputDecoration(labelText: 'اسم المستخدم بدون @')),
                const SizedBox(height: 10),
                TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'نبذة عنك')),
                SwitchListTile(value: isPrivate, onChanged: (v) => setDialogState(() => isPrivate = v), title: const Text('حساب خاص')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (result == true) {
      final handle = username.text.trim().toLowerCase().replaceFirst(RegExp(r'^@'), '');
      if (handle.isNotEmpty && !RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(handle)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اسم المستخدم: 3–24 حرفاً إنجليزياً أو رقماً أو _')));
      } else {
        try {
          final user = Supabase.instance.client.auth.currentUser!;
          await Supabase.instance.client.from('profiles').update({
            'display_name': name.text.trim(),
            'username': handle.isEmpty ? null : handle,
            'bio': bio.text.trim(),
            'is_private': isPrivate,
          }).eq('id', user.id);
          if (mounted) setState(() {});
        } on PostgrestException catch (error) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
        }
      }
    }
    name.dispose();
    username.dispose();
    bio.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXORA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [IconButton(tooltip: 'تسجيل الخروج', onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout))],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل الملف: ${snapshot.error}'));
          final profile = snapshot.data;
          if (profile == null) return const Center(child: Text('لم يتم العثور على ملفك الشخصي. أعد تسجيل الدخول.'));
          final displayName = profile['display_name'] as String? ?? 'مستخدم NEXORA';
          final handle = profile['username'] as String? ?? 'user';
          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const SizedBox(height: 16),
              const Center(child: _BrandMark()),
              const SizedBox(height: 20),
              Center(child: Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              Center(child: Text('@$handle', style: const TextStyle(color: Color(0xFF9CA3AF)))),
              const SizedBox(height: 12),
              Center(child: Text(profile['bio'] as String? ?? '', textAlign: TextAlign.center)),
              const SizedBox(height: 20),
              OutlinedButton.icon(onPressed: () => _editProfile(profile), icon: const Icon(Icons.edit_outlined), label: const Text('تعديل الملف الشخصي')),
              const SizedBox(height: 24),
              Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('حسابك متصل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 8),
                Text(user.email ?? 'بريد غير متاح', style: const TextStyle(color: Color(0xFF9CA3AF))),
                const SizedBox(height: 8),
                Text((profile['is_private'] as bool? ?? false) ? 'الحساب خاص' : 'الحساب عام', style: const TextStyle(color: Color(0xFF9CA3AF))),
              ]))),
              const SizedBox(height: 18),
              Text(['الرئيسية', 'استكشاف', 'إنشاء', 'الأصدقاء', 'ملفي'][_tab], textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF9CA3AF))),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'استكشاف'),
          NavigationDestination(icon: Icon(Icons.add_box_outlined), label: 'إنشاء'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'الأصدقاء'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'ملفي'),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
        height: 76,
        width: 76,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [Color(0xFF303541), Color(0xFF111319)]),
          border: Border.all(color: const Color(0xFF555B68)),
        ),
        child: const Icon(Icons.bolt_rounded, size: 42, color: Color(0xFFE8EAF0)),
      );
}
), '');
const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configured = _url.startsWith('https://') && _anonKey.isNotEmpty;
  if (configured) {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }
  runApp(NexoraApp(isConfigured: configured));
}

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key, required this.isConfigured});
  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF08090D);
    return MaterialApp(
      title: 'NEXORA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE8EAF0),
          secondary: Color(0xFF9CA3AF),
          surface: Color(0xFF14161D),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF14161D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: isConfigured ? const AuthGate() : const SetupScreen(),
      ),
    );
  }
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BrandMark(),
                const SizedBox(height: 24),
                const Text('NEXORA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 3)),
                const SizedBox(height: 12),
                const Text('التطبيق جاهز للاتصال بقاعدة البيانات', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                const Text('أضف SUPABASE_URL و SUPABASE_ANON_KEY كمتغيرات بناء آمنة في GitHub Actions. لا تضع مفتاح service_role داخل التطبيق أبداً.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9CA3AF), height: 1.6)),
              ],
            ),
          ),
        ),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        return session == null ? const AuthScreen() : const ProfileScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = true;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _message = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (_register) {
        final result = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'display_name': _name.text.trim()},
        );
        if (result.session == null && mounted) {
          setState(() => _message = 'تم إنشاء الطلب. راجع بريدك الإلكتروني لتأكيد الحساب ثم سجّل الدخول.');
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'حصل خطأ غير متوقع. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: _BrandMark()),
                      const SizedBox(height: 20),
                      const Text('NEXORA', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 3)),
                      const SizedBox(height: 8),
                      Text(_register ? 'ابدأ عالمك الخاص' : 'أهلاً بعودتك', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB7BBC6), fontSize: 17)),
                      const SizedBox(height: 30),
                      if (_register) ...[
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'الاسم الظاهر', prefixIcon: Icon(Icons.person_outline)),
                          validator: (v) => _register && (v == null || v.trim().length < 2) ? 'اكتب اسمك (حرفين على الأقل)' : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.mail_outline)),
                        validator: (v) => v == null || !v.contains('@') ? 'اكتب بريد إلكتروني صحيح' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock_outline)),
                        validator: (v) => v == null || v.length < 8 ? 'كلمة المرور 8 أحرف على الأقل' : null,
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 14),
                        Text(_message!, style: const TextStyle(color: Color(0xFFFFB4AB)), textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: _busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_register ? 'إنشاء حساب' : 'تسجيل الدخول', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: _busy ? null : () => setState(() { _register = !_register; _message = null; }),
                        child: Text(_register ? 'عندك حساب؟ سجّل الدخول' : 'لسه جديد؟ أنشئ حساب'),
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;

  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser!;
    return Supabase.instance.client.from('profiles').select().eq('id', user.id).maybeSingle();
  }

  Future<void> _editProfile(Map<String, dynamic> profile) async {
    final name = TextEditingController(text: profile['display_name'] as String? ?? '');
    final username = TextEditingController(text: profile['username'] as String? ?? '');
    final bio = TextEditingController(text: profile['bio'] as String? ?? '');
    var isPrivate = profile['is_private'] as bool? ?? false;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل الملف الشخصي'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم الظاهر')),
                const SizedBox(height: 10),
                TextField(controller: username, decoration: const InputDecoration(labelText: 'اسم المستخدم بدون @')),
                const SizedBox(height: 10),
                TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'نبذة عنك')),
                SwitchListTile(value: isPrivate, onChanged: (v) => setDialogState(() => isPrivate = v), title: const Text('حساب خاص')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (result == true) {
      final handle = username.text.trim().toLowerCase().replaceFirst(RegExp(r'^@'), '');
      if (handle.isNotEmpty && !RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(handle)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اسم المستخدم: 3–24 حرفاً إنجليزياً أو رقماً أو _')));
      } else {
        try {
          final user = Supabase.instance.client.auth.currentUser!;
          await Supabase.instance.client.from('profiles').update({
            'display_name': name.text.trim(),
            'username': handle.isEmpty ? null : handle,
            'bio': bio.text.trim(),
            'is_private': isPrivate,
          }).eq('id', user.id);
          if (mounted) setState(() {});
        } on PostgrestException catch (error) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
        }
      }
    }
    name.dispose();
    username.dispose();
    bio.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXORA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [IconButton(tooltip: 'تسجيل الخروج', onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout))],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل الملف: ${snapshot.error}'));
          final profile = snapshot.data;
          if (profile == null) return const Center(child: Text('لم يتم العثور على ملفك الشخصي. أعد تسجيل الدخول.'));
          final displayName = profile['display_name'] as String? ?? 'مستخدم NEXORA';
          final handle = profile['username'] as String? ?? 'user';
          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const SizedBox(height: 16),
              const Center(child: _BrandMark()),
              const SizedBox(height: 20),
              Center(child: Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              Center(child: Text('@$handle', style: const TextStyle(color: Color(0xFF9CA3AF)))),
              const SizedBox(height: 12),
              Center(child: Text(profile['bio'] as String? ?? '', textAlign: TextAlign.center)),
              const SizedBox(height: 20),
              OutlinedButton.icon(onPressed: () => _editProfile(profile), icon: const Icon(Icons.edit_outlined), label: const Text('تعديل الملف الشخصي')),
              const SizedBox(height: 24),
              Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('حسابك متصل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 8),
                Text(user.email ?? 'بريد غير متاح', style: const TextStyle(color: Color(0xFF9CA3AF))),
                const SizedBox(height: 8),
                Text((profile['is_private'] as bool? ?? false) ? 'الحساب خاص' : 'الحساب عام', style: const TextStyle(color: Color(0xFF9CA3AF))),
              ]))),
              const SizedBox(height: 18),
              Text(['الرئيسية', 'استكشاف', 'إنشاء', 'الأصدقاء', 'ملفي'][_tab], textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF9CA3AF))),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'استكشاف'),
          NavigationDestination(icon: Icon(Icons.add_box_outlined), label: 'إنشاء'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'الأصدقاء'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'ملفي'),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
        height: 76,
        width: 76,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [Color(0xFF303541), Color(0xFF111319)]),
          border: Border.all(color: const Color(0xFF555B68)),
        ),
        child: const Icon(Icons.bolt_rounded, size: 42, color: Color(0xFFE8EAF0)),
      );
}
