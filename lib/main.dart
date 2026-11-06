import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_error.dart';
import 'core/theme/nexora_theme.dart';
import 'core/widgets/nexora_glass.dart';
import 'features/auth/email_auth_validation.dart';
import 'features/design_gallery/design_gallery_screen.dart';
import 'features/preview/nexora_preview_screen.dart';
import 'features/media/media_upload_service.dart';
import 'features/media/post_media_gallery.dart';
import 'features/friends/friend_requests_screen.dart';
import 'features/friends/follow_requests_screen.dart';
import 'features/comments/comments_screen.dart';
import 'features/messaging/messages_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/notifications/nexora_push_service.dart';
import 'features/reels/reels_screen.dart';
import 'features/settings/privacy_settings_screen.dart';
import 'features/settings/appearance_settings_screen.dart';
import 'features/blocks/blocked_accounts_screen.dart';
import 'features/blocks/block_account_service.dart';
import 'features/stories/stories_screen.dart';
import 'features/search/hashtag_service.dart';
import 'features/nearby/nearby_discovery_screen.dart';
import 'features/communities/communities_screen.dart';
import 'features/moderation/report_dialog.dart';
import 'features/moderation/moderation_queue_screen.dart';
import 'features/moderation/my_moderation_screen.dart';


@pragma('vm:entry-point')
Future<void> _nexoraFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final _nexoraNavigatorKey = GlobalKey<NavigatorState>();
final _nexoraMessengerKey = GlobalKey<ScaffoldMessengerState>();

final _url = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://wwdeexgkwpftyavbhiff.supabase.co').trim();
const _key = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_vJpkaM72QMGLykLFU5m44g_kwuPCi-Y');

Future<void> _signOutNexora() async {
  await NexoraPushService.instance.unregisterCurrentDevice();
  try {
    await Supabase.instance.client.auth.signOut();
  } catch (_) {
    // If Supabase sign-out fails, restore push registration for the still
    // authenticated account rather than leaving notifications suspended.
    await NexoraPushService.instance.registerIfAllowed(
      resumeAfterSignIn: true,
    );
    rethrow;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorService.install();
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        _nexoraFirebaseMessagingBackgroundHandler,
      );
    } catch (e, s) {
      AppErrorService.report(e, s, source: 'firebase_startup');
    }
  }
  var ready = false;
  String? startupError;
  if (!_url.startsWith('https://') || _key.trim().isEmpty) {
    startupError = 'إعدادات الاتصال غير مكتملة. تحقق من عنوان Supabase ومفتاح Publishable/Anon.';
  } else {
    try {
      await Supabase.initialize(url: _url, publishableKey: _key.trim());
      ready = true;
      await NexoraPushService.instance.initialize();
    } catch (e, s) {
      AppErrorService.report(e, s, source: 'startup');
      startupError = AppErrorService.message(e);
    }
  }
  runApp(NexoraApp(ready: ready, startupError: startupError));
}

class NexoraApp extends StatefulWidget {
  const NexoraApp({super.key, required this.ready, this.startupError});
  final bool ready;
  final String? startupError;

  @override
  State<NexoraApp> createState() => _NexoraAppState();
}

class _NexoraAppState extends State<NexoraApp> {
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.ready) {
      _loadAppearance();
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.signedOut) {
          // Also clean up when the session ends outside the account-screen
          // button (for example, remote revocation or session invalidation).
          unawaited(NexoraPushService.instance.unregisterCurrentDevice());
        } else {
          final isNewSession = state.event == AuthChangeEvent.initialSession ||
              state.event == AuthChangeEvent.signedIn;
          NexoraPushService.instance.registerIfAllowed(
            resumeAfterSignIn: isNewSession,
          );
        }
        _loadAppearance();
      });
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((message) {
          final notification = message.notification;
          final title = notification?.title ?? 'NEXORA';
          final body = notification?.body ?? 'لديك إشعار جديد';
          _nexoraMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('$title: $body')),
          );
        });
        _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen((_) {
          _openNexoraNotifications();
        });
        FirebaseMessaging.instance.getInitialMessage().then((message) {
          if (message != null) _openNexoraNotifications();
        });
      }
    }
  }

  void _openNexoraNotifications() {
    _nexoraNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _loadAppearance() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      nexoraThemeNotifier.value = 'amoled';
      nexoraAccentNotifier.value = NexoraColors.violet;
      return;
    }
    try {
      final row = await client
          .from('user_preferences')
          .select('theme,accent_color')
          .eq('user_id', uid)
          .maybeSingle();
      if (client.auth.currentUser?.id != uid) return;
      nexoraThemeNotifier.value =
          normalizeNexoraTheme(row?['theme']?.toString());
      nexoraAccentNotifier.value =
          parseNexoraAccent(row?['accent_color']?.toString()) ??
          (nexoraThemeNotifier.value == 'pink_amoled'
              ? NexoraColors.pink
              : NexoraColors.violet);
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'load_appearance');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _openedMessageSubscription?.cancel();
    NexoraPushService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<String>(
        valueListenable: nexoraThemeNotifier,
        builder: (context, selected, _) =>
            ValueListenableBuilder<Color>(
          valueListenable: nexoraAccentNotifier,
          builder: (context, accent, _) {
            final theme = switch (selected) {
              'light' => NexoraTheme.light,
              'pink_amoled' => NexoraTheme.pinkAmoled,
              'custom' => NexoraTheme.custom(accent),
              _ => NexoraTheme.amoled,
            };
            return MaterialApp(
              navigatorKey: _nexoraNavigatorKey,
              scaffoldMessengerKey: _nexoraMessengerKey,
              title: 'NEXORA',
              debugShowCheckedModeBanner: false,
              theme: theme,
              darkTheme: theme,
              themeMode: ThemeMode.light,
              routes: kDebugMode ? {'/__design_gallery': (_) => const DesignGalleryScreen()} : const {},
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: widget.ready ? const AuthGate() : _Setup(error: widget.startupError),
              ),
            );
          },
        ),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: Supabase.instance.client.auth.onAuthStateChange,
    builder: (context, snap) {
      if (snap.data?.event == AuthChangeEvent.passwordRecovery) {
        return const PasswordRecoveryScreen();
      }
      final session =
          snap.data?.session ?? Supabase.instance.client.auth.currentSession;
      return session == null ? const AuthScreen() : const MainShell();
    },
  );
}

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _visible = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _password.text),
      );
      if (mounted) {
        setState(() => _notice = 'تم تحديث كلمة المرور بنجاح.');
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e, s) {
      AppErrorService.report(e, s, source: 'email_password_recovery');
      if (mounted) setState(() => _error = AppErrorService.message(e));
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
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _Brand(size: 76)),
                  const SizedBox(height: 20),
                  const Text(
                    'كلمة مرور جديدة',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'اختار كلمة مرور قوية لحساب NEXORA.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: NexoraColors.textMuted),
                  ),
                  const SizedBox(height: 26),
                  TextFormField(
                    controller: _password,
                    enabled: !_busy && _notice == null,
                    obscureText: !_visible,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _visible = !_visible),
                        icon: Icon(
                          _visible ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                    validator: (value) =>
                        NexoraEmailAuthValidation.password(
                      value,
                      registering: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirm,
                    enabled: !_busy && _notice == null,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    validator: (value) => value != _password.text
                        ? 'كلمتا المرور غير متطابقتين'
                        : null,
                  ),
                  if (_error != null) _Notice(text: _error!, error: true),
                  if (_notice != null) _Notice(text: _notice!, error: false),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy || _notice != null ? null : _savePassword,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('حفظ كلمة المرور الجديدة'),
                  ),
                  if (_notice != null)
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const MainShell(),
                        ),
                        (_) => false,
                      ),
                      child: const Text('متابعة إلى NEXORA'),
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

class _Setup extends StatelessWidget {
  const _Setup({this.error});
  final String? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _Empty(
              icon: Icons.cloud_off_outlined,
              title: 'تعذر الاتصال بخدمات NEXORA',
              subtitle: error == null || error!.isEmpty
                  ? 'تحقق من اتصال الإنترنت وإعدادات Supabase، ثم أعد تشغيل التطبيق.'
                  : 'تفاصيل الخطأ: $error',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const NexoraPreviewScreen()),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('استكشف NEXORA بدون اتصال · معاينة'),
                ),
              ),
            ),
          ]),
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
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _register = true;
  bool _busy = false;
  bool _visible = false;
  bool _emailConfirmationPending = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _clearFeedback() {
    _error = null;
    _notice = null;
  }

  String? _validateEmail(String? value) =>
      NexoraEmailAuthValidation.email(value);

  String? _validatePassword(String? value) =>
      NexoraEmailAuthValidation.password(value, registering: _register);

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _clearFeedback();
      _emailConfirmationPending = false;
    });
    try {
      final auth = Supabase.instance.client.auth;
      final email = _email.text.trim().toLowerCase();
      if (_register) {
        final result = await auth.signUp(
          email: email,
          password: _password.text,
          data: {'display_name': _name.text.trim()},
        );
        if (!mounted) return;
        if (result.session == null) {
          setState(() {
            _emailConfirmationPending = true;
            _notice = 'تم إنشاء الحساب. افتح رسالة NEXORA في بريدك واضغط رابط التأكيد لتفعيل الحساب. راجع مجلد Spam إذا لم تجد الرسالة.';
          });
        } else {
          setState(() => _notice = 'تم إنشاء حسابك بنجاح.');
        }
      } else {
        await auth.signInWithPassword(
          email: email,
          password: _password.text,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final message = e.message.toLowerCase();
      if (message.contains('email not confirmed')) {
        setState(() {
          _emailConfirmationPending = true;
          _notice = 'البريد الإلكتروني غير مؤكد. افتح رسالة التأكيد أو أعد إرسالها من الزر بالأسفل.';
        });
      } else {
        setState(() => _error = e.message);
      }
    } catch (e, s) {
      AppErrorService.report(e, s, source: 'email_auth');
      if (mounted) setState(() => _error = AppErrorService.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendEmailConfirmation() async {
    final email = _email.text.trim().toLowerCase();
    if (_validateEmail(email) != null) {
      setState(() => _error = 'اكتب بريدك الإلكتروني الصحيح أولًا');
      return;
    }
    setState(() {
      _busy = true;
      _clearFeedback();
    });
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      if (mounted) {
        setState(() {
          _emailConfirmationPending = true;
          _notice = 'تم طلب إعادة إرسال رابط التأكيد إلى $email. راجع صندوق الوارد ومجلد Spam.';
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e, s) {
      AppErrorService.report(e, s, source: 'email_auth_resend');
      if (mounted) setState(() => _error = AppErrorService.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _email.text.trim().toLowerCase();
    if (_validateEmail(email) != null) {
      setState(() => _error = 'اكتب البريد الإلكتروني المرتبط بحسابك أولًا');
      return;
    }
    setState(() {
      _busy = true;
      _clearFeedback();
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        setState(() {
          _notice = 'إذا كان البريد مرتبطًا بحساب، فستصلك رسالة لاستعادة كلمة المرور. راجع Spam أيضًا.';
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e, s) {
      AppErrorService.report(e, s, source: 'email_password_reset');
      if (mounted) setState(() => _error = AppErrorService.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                    const Text(
                      'NEXORA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _register ? 'مساحتك. صوتك. عالمك.' : 'رجعت تنوّر عالمك',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: NexoraColors.textMuted),
                    ),
                    const SizedBox(height: 28),
                    if (_register) ...[
                      TextFormField(
                        controller: _name,
                        enabled: !_busy,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'اسمك الظاهر',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => _register
                            ? NexoraEmailAuthValidation.displayName(v)
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        hintText: 'name@example.com',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: !_visible,
                      textDirection: TextDirection.ltr,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _visible ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور',
                          onPressed: () => setState(() => _visible = !_visible),
                          icon: Icon(
                            _visible ? Icons.visibility_off : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    if (_register)
                      const Padding(
                        padding: EdgeInsetsDirectional.only(top: 8, start: 4),
                        child: Text(
                          '12 حرفًا على الأقل، مع حرف إنجليزي ورقم.',
                          style: TextStyle(
                            color: NexoraColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_error != null) _Notice(text: _error!, error: true),
                    if (_notice != null) _Notice(text: _notice!, error: false),
                    if (_emailConfirmationPending)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _resendEmailConfirmation,
                          icon: const Icon(Icons.mark_email_unread_outlined),
                          label: const Text('إعادة إرسال رابط التأكيد'),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_register ? 'إنشاء حساب' : 'تسجيل الدخول'),
                    ),
                    if (!_register)
                      TextButton(
                        onPressed: _busy ? null : _sendPasswordReset,
                        child: const Text('نسيت كلمة المرور؟'),
                      ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _register = !_register;
                                _emailConfirmationPending = false;
                                _clearFeedback();
                              }),
                      child: Text(
                        _register
                            ? 'عندك حساب؟ سجّل الدخول'
                            : 'مستخدم جديد؟ أنشئ حساب',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const NexoraPreviewScreen(),
                                ),
                              ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('استكشف NEXORA قبل التسجيل · معاينة'),
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

  void _posted() => setState(() {
    _tab = 0;
    _feedVersion++;
  });

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(key: ValueKey(_feedVersion)),
      const ExploreScreen(),
      CreateScreen(onPosted: _posted),
      const MessagesScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _NexoraAuroraBackdrop()),
          Positioned.fill(
            bottom: 108,
            child: IndexedStack(index: _tab, children: pages),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 8,
            child: SafeArea(
              top: false,
              child: NexoraGlass(
                radius: NexoraRadius.sheet,
                blur: 30,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                child: Row(
                  children: [
                    _NexoraNavItem(
                      icon: Icons.home_rounded,
                      label: 'الرئيسية',
                      selected: _tab == 0,
                      onTap: () => setState(() => _tab = 0),
                    ),
                    _NexoraNavItem(
                      icon: Icons.explore_rounded,
                      label: 'استكشف',
                      selected: _tab == 1,
                      onTap: () => setState(() => _tab = 1),
                    ),
                    Expanded(
                      child: Center(
                        child: Semantics(
                          button: true,
                          label: 'إنشاء محتوى',
                          child: GestureDetector(
                            onTap: () => setState(() => _tab = 2),
                            child: AnimatedScale(
                              scale: _tab == 2 ? 1.06 : 1,
                              duration: MediaQuery.of(context).disableAnimations
                                  ? Duration.zero
                                  : NexoraMotion.standard,
                              curve: Curves.easeOutBack,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: NexoraColors.brandGradient,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: NexoraColors.violet.withValues(alpha: .30),
                                      blurRadius: 20,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 29,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _NexoraNavItem(
                      icon: Icons.forum_rounded,
                      label: 'الدردشة',
                      selected: _tab == 3,
                      onTap: () => setState(() => _tab = 3),
                    ),
                    _NexoraNavItem(
                      icon: Icons.person_rounded,
                      label: 'حسابي',
                      selected: _tab == 4,
                      onTap: () => setState(() => _tab = 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NexoraNavItem extends StatelessWidget {
  const _NexoraNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(NexoraRadius.pill),
          onTap: onTap,
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : NexoraMotion.standard,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? NexoraColors.violet.withValues(alpha: .13)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(NexoraRadius.pill),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1,
                  duration: reduceMotion
                      ? Duration.zero
                      : NexoraMotion.standard,
                  curve: Curves.easeOutBack,
                  child: Icon(
                    icon,
                    size: 22,
                    color: selected
                        ? NexoraColors.cyan
                        : NexoraColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? NexoraColors.text
                        : NexoraColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NexoraAuroraBackdrop extends StatelessWidget {
  const _NexoraAuroraBackdrop();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: NexoraColors.bg,
    child: Stack(
      children: [
        Positioned(
          top: -170,
          right: -150,
          child: _NexoraGlow(color: NexoraColors.violet, size: 330),
        ),
        Positioned(
          top: 300,
          left: -210,
          child: _NexoraGlow(color: NexoraColors.cyan, size: 310),
        ),
        Positioned(
          bottom: -220,
          right: 10,
          child: _NexoraGlow(color: NexoraColors.pink, size: 320),
        ),
      ],
    ),
  );
}

class _NexoraGlow extends StatelessWidget {
  const _NexoraGlow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .11),
            blurRadius: 110,
            spreadRadius: 24,
          ),
        ],
      ),
    ),
  );
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
  int _nextOffset = 0;
  int _requestGeneration = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<List<Map<String, dynamic>>> _fetchPage(int offset) async {
    final client = Supabase.instance.client;
    final rows = await client.rpc(
      'get_feed_page',
      params: {
        'p_mode': _mode == _FeedMode.latest ? 'latest' : 'following',
        'p_limit': _pageSize,
        'p_offset': offset,
      },
    );
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _loadFirstPage() async {
    final generation = ++_requestGeneration;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _hasMore = true;
      _nextOffset = 0;
      _error = null;
      _posts.clear();
    });
    try {
      final rows = await _fetchPage(0);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _posts.addAll(rows);
        _nextOffset = rows.length;
        _hasMore = rows.length == _pageSize;
        _loading = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'feed_initial');
      if (mounted && generation == _requestGeneration) {
        setState(() {
          _error = AppErrorService.message(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _error != null) return;
    final generation = _requestGeneration;
    setState(() => _loadingMore = true);
    try {
      final rows = await _fetchPage(_nextOffset);
      if (!mounted || generation != _requestGeneration) return;
      final knownIds = _posts.map((p) => p['id']).toSet();
      final uniqueRows = rows.where((p) => !knownIds.contains(p['id']));
      setState(() {
        _posts.addAll(uniqueRows);
        // Advance by backend rows fetched, not only newly visible rows.
        _nextOffset += rows.length;
        _hasMore = rows.length == _pageSize;
        _loadingMore = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'feed_more');
      if (mounted && generation == _requestGeneration) {
        setState(() {
          _error = AppErrorService.message(error);
          _loadingMore = false;
        });
      }
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
      title: GestureDetector(onLongPress: kDebugMode ? () => Navigator.of(context).pushNamed('/__design_gallery') : null, child: const Text('NEXORA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2))),
      actions: [
        IconButton(tooltip: 'معاينة NEXORA', onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NexoraPreviewScreen())), icon: const Icon(Icons.visibility_outlined)),
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
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: NexoraColors.surface,
                            borderRadius: BorderRadius.circular(NexoraRadius.sheet),
                            border: Border.all(color: NexoraColors.hairline),
                            gradient: const LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Color(0xFF1B142D),
                                NexoraColors.surface,
                                Color(0xFF101018),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(13),
                                      gradient: const LinearGradient(
                                        colors: NexoraColors.brandGradient,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Colors.white,
                                      size: 23,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  const Text(
                                    'N E X O R A',
                                    style: TextStyle(
                                      color: NexoraColors.text,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.bolt_rounded,
                                    color: NexoraColors.amber,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'مساحتك. صوتك. عالمك.',
                                style: TextStyle(
                                  color: NexoraColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 7),
                              const Text(
                                'خلّي حضورك يُحكى.',
                                style: TextStyle(
                                  color: NexoraColors.text,
                                  fontSize: 26,
                                  height: 1.18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'شارك لحظاتك واكتشف ناس شبهك.',
                                style: TextStyle(
                                  color: NexoraColors.textMuted,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
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
                            child: Center(child: Text('وصلت لآخر المنشورات', style: TextStyle(color: NexoraColors.textMuted))),
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
    final me = client.auth.currentUser?.id;
    if (me == null) throw StateError('يجب تسجيل الدخول لعرض المحتوى.');
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
    if (client.auth.currentUser?.id != me) {
      throw StateError('تغير الحساب أثناء تحميل الأشخاص.');
    }
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
              tooltip: 'ريلز',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ReelsScreen(),
                ),
              ),
              icon: const Icon(Icons.play_circle_outline_rounded),
            ),
            IconButton(
              tooltip: 'الأشخاص القريبون',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NearbyDiscoveryScreen(),
                ),
              ),
              icon: const Icon(Icons.near_me_outlined),
            ),
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
              tooltip: 'طلبات المتابعة',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FollowRequestsScreen(),
                ),
              ),
              icon: const Icon(Icons.person_add_alt),
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
                            : PersonTile(key: ValueKey(people[index]['id']), profile: people[index], follow: true);
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
  static const int _pageSize = 30;
  final List<Map<String, dynamic>> _rows = [];
  bool _showFollowers = false;
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _loadError;
  int _offset = 0;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<List<Map<String, dynamic>>> _fetchPage(int offset) async {
    final client = Supabase.instance.client;
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('يجب تسجيل الدخول لعرض القائمة.');
    final profileRelation = _showFollowers
        ? 'profiles!follows_follower_id_fkey'
        : 'profiles!follows_following_id_fkey';
    final profileFields =
        '$profileRelation(id,username,display_name,bio,avatar_url,is_verified)';
    final rows = await client
        .from('follows')
        .select('follower_id,following_id,created_at,$profileFields')
        .eq(_showFollowers ? 'following_id' : 'follower_id', id)
        .eq('status', 'accepted')
        .order('created_at', ascending: false)
        .order(_showFollowers ? 'follower_id' : 'following_id', ascending: true)
        .range(offset, offset + _pageSize - 1);
    if (client.auth.currentUser?.id != id) {
      throw StateError('تغير الحساب أثناء تحميل قائمة الأصدقاء.');
    }
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _loadFirstPage() async {
    if (!mounted) return;
    final generation = ++_requestGeneration;
    setState(() {
      _initialLoading = true;
      _loadingMore = false;
      _loadError = null;
      _offset = 0;
      _hasMore = true;
      _rows.clear();
    });
    try {
      final rows = await _fetchPage(0);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _rows.addAll(rows);
        _offset = rows.length;
        _hasMore = rows.length == _pageSize;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'friends_list_load');
      if (mounted && generation == _requestGeneration) {
        setState(() => _loadError = error);
      }
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() => _initialLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _initialLoading) return;
    final generation = _requestGeneration;
    setState(() => _loadingMore = true);
    try {
      final rows = await _fetchPage(_offset);
      if (!mounted || generation != _requestGeneration) return;
      final relationshipKey = _showFollowers ? 'follower_id' : 'following_id';
      final knownIds = _rows.map((row) => row[relationshipKey]).toSet();
      final additions = rows.where(
        (row) => !knownIds.contains(row[relationshipKey]),
      );
      setState(() {
        _rows.addAll(additions);
        // Offset tracks backend rows fetched, not only newly visible rows.
        _offset += rows.length;
        _hasMore = rows.length == _pageSize;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'friends_list_load_more');
      if (mounted && generation == _requestGeneration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _removeFollowing(String userId) {
    final previousLength = _rows.length;
    _requestGeneration++;
    setState(() {
      _rows.removeWhere((row) => row['following_id'] == userId);
      if (_rows.length < previousLength && _offset > 0) _offset--;
      _loadingMore = false;
    });
  }

  void _switchList(bool showFollowers) {
    if (_showFollowers == showFollowers) return;
    setState(() => _showFollowers = showFollowers);
    _loadFirstPage();
  }

  Widget _buildPerson(Map<String, dynamic> row) {
    final profile = row['profiles'];
    if (profile is! Map) {
      return Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.lock_outline)),
          title: const Text('حساب خاص'),
          subtitle: const Text('الملف الشخصي غير متاح'),
        ),
      );
    }
    final profileMap = Map<String, dynamic>.from(profile);
    return PersonTile(
      key: ValueKey(profileMap['id']),
      profile: profileMap,
      follow: true,
      onUnfollow: _showFollowers
          ? null
          : () => _removeFollowing(profileMap['id'].toString()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('مجتمعك', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _initialLoading ? null : _loadFirstPage,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('أتابعهم'),
                    icon: Icon(Icons.person_add_alt),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('متابعيني'),
                    icon: Icon(Icons.people_alt_outlined),
                  ),
                ],
                selected: {_showFollowers},
                onSelectionChanged: (selection) => _switchList(selection.first),
              ),
            ),
            Expanded(
              child: _initialLoading && _rows.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null && _rows.isEmpty
                      ? AppErrorView(
                          title: 'تعذر تحميل القائمة',
                          error: _loadError,
                          onRetry: _loadFirstPage,
                        )
                      : _rows.isEmpty
                          ? _Empty(
                              icon: _showFollowers
                                  ? Icons.people_outline
                                  : Icons.group_add,
                              title: _showFollowers
                                  ? 'لسه مفيش متابعين'
                                  : 'شبكتك لسه بتبدأ',
                              subtitle: _showFollowers
                                  ? 'لما حد يتابعك هتلاقيه هنا.'
                                  : 'اكتشف أشخاص وتابعهم عشان يظهروا هنا.',
                            )
                          : RefreshIndicator(
                              onRefresh: _loadFirstPage,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: _rows.length + (_hasMore ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  if (i == _rows.length) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: OutlinedButton.icon(
                                          onPressed: _loadingMore ? null : _loadMore,
                                          icon: _loadingMore
                                              ? const SizedBox.square(
                                                  dimension: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.expand_more),
                                          label: Text(_loadingMore ? 'جارٍ التحميل...' : 'تحميل المزيد'),
                                        ),
                                      ),
                                    );
                                  }
                                  return _buildPerson(_rows[i]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      );
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
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _error = 'انتهت جلسة الدخول. سجّل الدخول مرة تانية.');
      return;
    }
    setState(() { _busy = true; _error = null; });
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
        style: TextStyle(color: NexoraColors.textMuted, height: 1.5)),
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
  late Future<Map<String, dynamic>?> _staffFuture;
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
    _staffFuture = _loadStaffRole();
    _postsFuture = _loadOwnPosts();
  }
  Future<Map<String, dynamic>?> _loadStaffRole() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      return await Supabase.instance.client
          .from('staff_members')
          .select('role')
          .eq('user_id', uid)
          .maybeSingle();
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'profile_staff_role');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _load() async {
    final u = Supabase.instance.client.auth.currentUser!;
    return Supabase.instance.client.from('profiles').select().eq('id', u.id).maybeSingle();
  }
  Future<List<Map<String, dynamic>>> _loadOwnPosts({int offset = 0}) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('انتهت جلسة الدخول.');
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
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('ملفي الشخصي', style: TextStyle(fontWeight: FontWeight.w800)), actions: [
    FutureBuilder<Map<String, dynamic>?>(
      future: _staffFuture,
      builder: (context, snapshot) {
        final role = snapshot.data?['role']?.toString();
        if (!const {'super_admin', 'admin', 'moderator', 'support'}.contains(role)) {
          return const SizedBox.shrink();
        }
        return IconButton(
          tooltip: 'مركز مراجعة البلاغات',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ModerationQueueScreen(role: role!),
            ),
          ),
          icon: const Icon(Icons.gavel_outlined),
        );
      },
    ),
    IconButton(
      tooltip: 'إجراءاتي والاستئنافات',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const MyModerationScreen(),
        ),
      ),
      icon: const Icon(Icons.gavel_outlined),
    ),
    IconButton(
      tooltip: 'المظهر',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AppearanceSettingsScreen(),
        ),
      ),
      icon: const Icon(Icons.palette_outlined),
    ),
    IconButton(
      tooltip: 'الحسابات المحظورة',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const BlockedAccountsScreen(),
        ),
      ),
      icon: const Icon(Icons.block_outlined),
    ),
    IconButton(tooltip: 'مركز الخصوصية', onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PrivacySettingsScreen())), icon: const Icon(Icons.shield_outlined)), IconButton(tooltip: 'تسجيل الخروج', onPressed: () => _signOutNexora(), icon: const Icon(Icons.logout))]), body: FutureBuilder<Map<String, dynamic>?>(future: _future, builder: (context, snap) {
    if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    if (snap.hasError) return AppErrorView(title: 'تعذر تحميل حسابك', error: snap.error, onRetry: () => setState(() => _future = _load()));
    final p = snap.data;
    if (p == null) return const _Empty(icon: Icons.person_off, title: 'الملف الشخصي غير موجود', subtitle: 'راجع إعداد إنشاء صف profiles عند تسجيل الحساب.');
    final u = Supabase.instance.client.auth.currentUser!;
    return ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.fromLTRB(16, 12, 16, 22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: [NexoraColors.surfaceRaised, NexoraColors.surface]), border: Border.all(color: NexoraColors.hairline)), child: Column(children: [
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
      const SizedBox(height: 20), OutlinedButton.icon(onPressed: _signOutNexora, icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
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

  Future<void> _blockPostAuthor() async {
    try {
      final profile = widget.post['profiles'];
      final displayName = profile is Map
          ? (profile['display_name'] ?? profile['username'] ?? 'صاحب المنشور')
              .toString()
          : 'صاحب المنشور';
      final blocked = await BlockAccountService.confirmAndBlock(
        context,
        targetUserId: widget.post['user_id'] as String,
        displayName: displayName,
      );
      if (blocked && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حظر الحساب')),
        );
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'block_post_author');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    }
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
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتهت جلسة الدخول. سجّل الدخول مرة تانية.')),
      );
      return;
    }
    setState(() => _saveBusy = true);
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
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتهت جلسة الدخول. سجّل الدخول مرة تانية.')),
      );
      return;
    }
    setState(() => _busy = true);
    final pid = widget.post['id'] as String;
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
      Row(children: [_ProfileAvatar(url: a is Map ? a['avatar_url']?.toString() : null), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w800)), Text('@' + handle + ' • ' + stamp, style: const TextStyle(fontSize: 11, color: NexoraColors.textMuted))])), PopupMenuButton<String>(
        tooltip: 'خيارات المنشور',
        onSelected: (value) async {
          if (value == 'block_user') {
            await _blockPostAuthor();
            return;
          }
          if (value == 'report' || value == 'report_user') {
            final isUserReport = value == 'report_user';
            final submitted = await ReportDialog.show(
              context,
              targetType: isUserReport ? 'user' : 'post',
              targetId: isUserReport
                  ? widget.post['user_id'] as String
                  : widget.post['id'] as String,
            );
            if (submitted && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرسال البلاغ للمراجعة')),
              );
            }
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 18),
                SizedBox(width: 8),
                Text('إبلاغ عن المنشور'),
              ],
            ),
          ),
          if (widget.post['user_id'] !=
              Supabase.instance.client.auth.currentUser?.id) ...[
            const PopupMenuItem(
              value: 'block_user',
              child: Row(
                children: [
                  Icon(Icons.block_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('حظر صاحب الحساب'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report_user',
              child: Row(
                children: [
                  Icon(Icons.person_off_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('إبلاغ عن الحساب'),
                ],
              ),
            ),
          ],
        ],
      )]),
      if ((widget.post['content'] ?? '').toString().isNotEmpty)
        Text((widget.post['content'] ?? '').toString(), style: const TextStyle(fontSize: 15, height: 1.65)),
      PostMediaGallery(postId: widget.post['id'] as String),
      const Divider(height: 24, color: NexoraColors.hairline),
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
              : Icon(_reposted ? Icons.repeat_on : Icons.repeat, color: _reposted ? NexoraColors.success : null),
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
  const PersonTile({super.key, required this.profile, required this.follow, this.onUnfollow});
  final Map<String, dynamic> profile;
  final bool follow;
  final VoidCallback? onUnfollow;
  @override
  State<PersonTile> createState() => _PersonTileState();
}
class _PersonTileState extends State<PersonTile> {
  String? _followStatus;
  bool _busy = true;
  bool _blocked = false;
  int _relationshipGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadRelationshipState();
  }

  @override
  void didUpdateWidget(covariant PersonTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile['id'] != widget.profile['id'] ||
        oldWidget.follow != widget.follow) {
      _relationshipGeneration++;
      _followStatus = null;
      _blocked = false;
      _busy = true;
      _loadRelationshipState();
    }
  }

  Future<void> _loadRelationshipState() async {
    final generation = ++_relationshipGeneration;
    final client = Supabase.instance.client;
    final me = client.auth.currentUser?.id;
    final other = widget.profile['id']?.toString();
    if (me == null || other == null) {
      if (mounted && generation == _relationshipGeneration) {
        setState(() => _busy = false);
      }
      return;
    }
    try {
      final block = await client
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', me)
          .eq('blocked_id', other)
          .maybeSingle();
      Map<String, dynamic>? follow;
      if (widget.follow && block == null) {
        follow = await client
            .from('follows')
            .select('status')
            .eq('follower_id', me)
            .eq('following_id', other)
            .maybeSingle();
      }
      if (!mounted ||
          generation != _relationshipGeneration ||
          widget.profile['id']?.toString() != other ||
          client.auth.currentUser?.id != me) {
        return;
      }
      setState(() {
        _blocked = block != null;
        _followStatus = follow?['status'] as String?;
        _busy = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'load_person_relationship');
      if (mounted && generation == _relationshipGeneration) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _blockAccount() async {
    final generation = _relationshipGeneration;
    final targetId = widget.profile['id'] as String;
    try {
      final blocked = await BlockAccountService.confirmAndBlock(
        context,
        targetUserId: targetId,
        displayName: (widget.profile['display_name'] ??
                widget.profile['username'] ??
                'الحساب')
            .toString(),
      );
      if (!mounted ||
          !blocked ||
          generation != _relationshipGeneration ||
          widget.profile['id']?.toString() != targetId) {
        return;
      }
      setState(() => _blocked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حظر الحساب')),
      );
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'block_account');
      if (mounted && generation == _relationshipGeneration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final generation = _relationshipGeneration;
    final other = widget.profile['id'] as String;
    final wasAccepted = _followStatus == 'accepted';
    setState(() => _busy = true);
    try {
      if (_followStatus == null) {
        final status = await Supabase.instance.client.rpc(
          'request_follow',
          params: {'p_target_user_id': other},
        );
        if (mounted &&
            generation == _relationshipGeneration &&
            widget.profile['id']?.toString() == other) {
          setState(() => _followStatus = status.toString());
        }
      } else {
        await Supabase.instance.client.rpc(
          'cancel_follow',
          params: {'p_target_user_id': other},
        );
        if (mounted &&
            generation == _relationshipGeneration &&
            widget.profile['id']?.toString() == other) {
          setState(() => _followStatus = null);
          if (wasAccepted) widget.onUnfollow?.call();
        }
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'follow');
      if (mounted && generation == _relationshipGeneration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    } finally {
      if (mounted && generation == _relationshipGeneration) {
        setState(() => _busy = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Card(child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [
      _ProfileAvatar(url: p['avatar_url']?.toString(), size: 48), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Flexible(child: Text((p['display_name'] ?? 'مستخدم').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))), if (p['is_verified'] == true) const Icon(Icons.verified, size: 16, color: NexoraColors.cyan)]),
        Text('@' + (p['username'] ?? 'user').toString(), style: const TextStyle(color: NexoraColors.textMuted, fontSize: 12)),
        if ((p['bio'] ?? '').toString().isNotEmpty) Text(p['bio'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NexoraColors.textMuted, fontSize: 12)),
      ])),
      if (p['id'] != Supabase.instance.client.auth.currentUser?.id)
        PopupMenuButton<String>(
          tooltip: 'خيارات الحساب',
          onSelected: (value) async {
            if (value == 'block') {
              await _blockAccount();
              return;
            }
            if (value == 'report') {
              final submitted = await ReportDialog.show(
                context,
                targetType: 'user',
                targetId: p['id'] as String,
              );
              if (submitted && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال البلاغ للمراجعة')),
                );
              }
            }
          },
          itemBuilder: (_) => [
            if (!_blocked)
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('حظر الحساب'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('الإبلاغ عن الحساب'),
                ],
              ),
            ),
          ],
        ),
      if (!_blocked) FriendRequestAction(otherUserId: p['id'] as String),
      if (_blocked)
        const Chip(label: Text('محظور')),
      if (widget.follow && !_blocked) OutlinedButton(onPressed: _busy ? null : _toggle, child: _busy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_followStatus == 'pending' ? 'إلغاء الطلب' : (_followStatus == 'accepted' ? 'إلغاء المتابعة' : 'متابعة'))),
    ])));
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.size = 46});
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * .3), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: NexoraColors.brandGradient), border: Border.all(color: const Color(0x99FFFFFF)), boxShadow: const [BoxShadow(color: Color(0x6654CFFF), blurRadius: 26, offset: Offset(0, 8))]), child: Icon(Icons.bolt_rounded, color: Colors.white, size: size * .58));
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
    decoration: BoxDecoration(shape: BoxShape.circle, color: NexoraColors.surfaceRaised, border: Border.all(color: NexoraColors.hairline)),
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
          ? Container(color: NexoraColors.surfaceRaised, child: const Center(child: Icon(Icons.landscape_outlined, size: 38, color: NexoraColors.textMuted)))
          : Image.network(snapshot.data!, fit: BoxFit.cover, width: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: NexoraColors.surfaceRaised, child: const Icon(Icons.broken_image_outlined, color: NexoraColors.textMuted))),
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.title, required this.value});
  final IconData icon; final String title, value;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: NexoraColors.textMuted), title: Text(title, style: const TextStyle(fontSize: 12, color: NexoraColors.textMuted)), subtitle: Text(value)));
}
class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.error});
  final String text; final bool error;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: error ? NexoraColors.danger.withValues(alpha: .12) : NexoraColors.success.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: error ? NexoraColors.danger : NexoraColors.text)));
}
class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.subtitle});
  final IconData icon; final String title, subtitle;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 54, color: NexoraColors.text), const SizedBox(height: 18), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: NexoraColors.textMuted, height: 1.6))])));
}
