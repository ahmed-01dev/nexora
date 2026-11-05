import 'package:flutter/material.dart';
import '../../core/theme/nexora_theme.dart';
import '../../core/widgets/nexora_glass.dart';

/// Interactive visual prototype. All sample data and commerce flows are local-only.
class NexoraPreviewScreen extends StatefulWidget {
  const NexoraPreviewScreen({super.key});

  @override
  State<NexoraPreviewScreen> createState() => _NexoraPreviewScreenState();
}

class _NexoraPreviewScreenState extends State<NexoraPreviewScreen> {
  int _tab = 0;
  final Set<int> _liked = {};
  final Set<int> _saved = {};
  final Set<int> _following = {};

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF20202B),
        content: Text(message, textDirection: TextDirection.rtl),
      ));
  }

  void _showCreate() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PreviewSheet(
        title: 'ابدأ شيئًا جديدًا',
        child: Column(children: [
          _SheetAction(icon: Icons.article_outlined, title: 'منشور جديد', subtitle: 'شارك فكرة أو صورة أو فيديو', onTap: () { Navigator.pop(context); _toast('معاينة إنشاء المنشور — الربط قادم'); }),
          _SheetAction(icon: Icons.auto_awesome, title: 'قصة جديدة', subtitle: 'لحظات تختفي بعد 24 ساعة', onTap: () { Navigator.pop(context); _toast('معاينة القصص — الربط قادم'); }),
          _SheetAction(icon: Icons.video_collection_outlined, title: 'فيديو قصير', subtitle: 'اصنع Reel خاص بك', onTap: () { Navigator.pop(context); _toast('معاينة إنشاء الفيديو — الربط قادم'); }),
          _SheetAction(icon: Icons.poll_outlined, title: 'استطلاع رأي', subtitle: 'اسأل مجتمعك', onTap: () { Navigator.pop(context); _toast('معاينة الاستطلاعات — الربط قادم'); }),
        ]),
      ),
    );
  }

  void _openPremium() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const NexoraPremiumPreviewScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomePreview(
        liked: _liked,
        saved: _saved,
        following: _following,
        onLike: (id) => setState(() => _liked.contains(id) ? _liked.remove(id) : _liked.add(id)),
        onSave: (id) => setState(() => _saved.contains(id) ? _saved.remove(id) : _saved.add(id)),
        onFollow: (id) => setState(() => _following.contains(id) ? _following.remove(id) : _following.add(id)),
        onComment: () => _toast('نافذة التعليقات — بيانات تجريبية'),
        onShare: () => _toast('قائمة المشاركة — معاينة'),
      ),
      _ExplorePreview(onOpen: _toast),
      _CreateLanding(onCreate: _showCreate),
      _ChatListPreview(onOpen: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _ChatPreviewScreen()))),
      _ProfilePreview(onPremium: _openPremium, onOpen: _toast),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBody: true,
        body: Stack(children: [
          const Positioned.fill(child: _AuroraBackdrop()),
          SafeArea(bottom: false, child: IndexedStack(index: _tab, children: pages)),
          Positioned(
            left: 16, right: 16, bottom: 12,
            child: SafeArea(
              top: false,
              child: NexoraGlass(
                radius: 28,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                child: Row(
                  children: [
                    _NavItem(icon: Icons.home_rounded, label: 'الرئيسية', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                    _NavItem(icon: Icons.explore_rounded, label: 'استكشف', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                    Expanded(child: Center(child: GestureDetector(
                      onTap: _showCreate,
                      child: Container(
                        width: 48, height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: NexoraColors.brandGradient),
                          boxShadow: [BoxShadow(color: Color(0x667C5CFF), blurRadius: 18, offset: Offset(0, 5))],
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                      ),
                    ))),
                    _NavItem(icon: Icons.forum_rounded, label: 'الدردشة', selected: _tab == 3, onTap: () => setState(() => _tab = 3)),
                    _NavItem(icon: Icons.person_rounded, label: 'حسابي', selected: _tab == 4, onTap: () => setState(() => _tab = 4)),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AuroraBackdrop extends StatelessWidget {
  const _AuroraBackdrop();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: NexoraColors.bg),
    child: Stack(children: [
      Positioned(top: -130, right: -90, child: _GlowBlob(color: NexoraColors.violet, size: 310)),
      Positioned(top: 210, left: -160, child: _GlowBlob(color: NexoraColors.cyan, size: 290)),
      Positioned(bottom: -180, right: 40, child: _GlowBlob(color: NexoraColors.pink, size: 280)),
      const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0x22000000), Color(0xCC000000)], stops: [0, .82]),
      ))),
    ]),
  );
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: .10),
      boxShadow: [BoxShadow(color: color.withValues(alpha: .22), blurRadius: 100, spreadRadius: 28)]));
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(child: InkWell(
    borderRadius: BorderRadius.circular(20), onTap: onTap,
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 22, color: selected ? NexoraColors.cyan : NexoraColors.textMuted),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? NexoraColors.text : NexoraColors.textMuted)),
      ]),
    ),
  ));
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, this.subtitle, this.action});
  final String title; final String? subtitle; final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -.5)),
        if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: const TextStyle(color: NexoraColors.textMuted, fontSize: 12))],
      ])),
      if (action != null) action!,
    ]),
  );
}

class _HomePreview extends StatelessWidget {
  const _HomePreview({required this.liked, required this.saved, required this.following, required this.onLike, required this.onSave, required this.onFollow, required this.onComment, required this.onShare});
  final Set<int> liked, saved, following;
  final ValueChanged<int> onLike, onSave, onFollow;
  final VoidCallback onComment, onShare;
  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
    SliverToBoxAdapter(child: _PageHeader(title: 'NEXORA', subtitle: 'مساحتك. صوتك. عالمك.', action: Row(children: [
      IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الإشعارات — معاينة'))), icon: const Icon(Icons.notifications_none_rounded)),
      IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NexoraPremiumPreviewScreen())), icon: const Icon(Icons.diamond_outlined, color: NexoraColors.amber)),
    ]))),
    SliverToBoxAdapter(child: SizedBox(height: 102, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: const [
      _StoryAvatar(name: 'قصتك', own: true, color: NexoraColors.violet),
      _StoryAvatar(name: 'سارة', color: NexoraColors.pink),
      _StoryAvatar(name: 'عمر', color: NexoraColors.cyan),
      _StoryAvatar(name: 'ليلى', color: NexoraColors.amber),
      _StoryAvatar(name: 'يوسف', color: NexoraColors.violet),
      _StoryAvatar(name: 'Mira', color: NexoraColors.cyan),
    ]))),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18, 10, 18, 12), child: Row(children: [
      const Text('آخر المنشورات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      const Spacer(),
      TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عرض الأحدث — بيانات المعاينة'))), child: const Text('الأحدث')),
      TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عرض من تتابعهم — بيانات المعاينة'))), child: const Text('أتابعهم')),
    ]))),
    SliverList(delegate: SliverChildListDelegate([
      _PostPreview(id: 1, name: 'Nour Hassan', handle: '@nour.h', time: 'منذ 12 دقيقة', text: 'أحيانًا أجمل اللحظات هي اللي بنشاركها من غير ترتيب. ✨', colors: const [Color(0xFF36216C), Color(0xFF176C83)], likes: '2.4K', comments: '184', isLiked: liked.contains(1), isSaved: saved.contains(1), isFollowing: following.contains(1), onLike: () => onLike(1), onSave: () => onSave(1), onFollow: () => onFollow(1), onComment: onComment, onShare: onShare),
      _PostPreview(id: 2, name: 'Omar Adel', handle: '@omar.adel', time: 'منذ ساعة', text: 'بداية جديدة، وأفكار كتير مستنية تتحول لحاجة حقيقية.', colors: const [Color(0xFF164D57), Color(0xFF1D275B)], likes: '986', comments: '72', isLiked: liked.contains(2), isSaved: saved.contains(2), isFollowing: following.contains(2), onLike: () => onLike(2), onSave: () => onSave(2), onFollow: () => onFollow(2), onComment: onComment, onShare: onShare),
    ])),
    const SliverToBoxAdapter(child: SizedBox(height: 112)),
  ]);
}

class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({required this.name, required this.color, this.own = false});
  final String name; final Color color; final bool own;
  @override
  Widget build(BuildContext context) => SizedBox(width: 76, child: InkWell(
    borderRadius: BorderRadius.circular(40),
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(own ? 'إضافة قصتك — معاينة' : 'قصة $name — معاينة'))),
    child: Column(children: [
      Container(padding: const EdgeInsets.all(2.5), decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: LinearGradient(colors: own ? [NexoraColors.textFaint, NexoraColors.textFaint] : NexoraColors.brandGradient)),
        child: CircleAvatar(radius: 27, backgroundColor: const Color(0xFF20202A), child: Icon(own ? Icons.person : Icons.face_rounded, color: color, size: 27))),
      const SizedBox(height: 5), Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: NexoraColors.textMuted)),
    ]),
  ));
}

class _PostPreview extends StatelessWidget {
  const _PostPreview({required this.id, required this.name, required this.handle, required this.time, required this.text, required this.colors, required this.likes, required this.comments, required this.isLiked, required this.isSaved, required this.isFollowing, required this.onLike, required this.onSave, required this.onFollow, required this.onComment, required this.onShare});
  final int id; final String name, handle, time, text, likes, comments; final List<Color> colors;
  final bool isLiked, isSaved, isFollowing; final VoidCallback onLike, onSave, onFollow, onComment, onShare;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 5, 16, 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(backgroundColor: colors.first, child: const Icon(Icons.person, color: Colors.white)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('$handle · $time', style: const TextStyle(color: NexoraColors.textMuted, fontSize: 11)),
        ])),
        TextButton(onPressed: onFollow, child: Text(isFollowing ? 'تتابعه' : 'متابعة')),
        IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خيارات المنشور — معاينة'))), icon: const Icon(Icons.more_horiz)),
      ]),
      const SizedBox(height: 10),
      Text(text, style: const TextStyle(fontSize: 14, height: 1.6)),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(20), child: AspectRatio(aspectRatio: 1.35,
        child: Stack(fit: StackFit.expand, children: [
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors))),
          Positioned(top: 25, right: 25, child: Icon(Icons.blur_on, color: Colors.white.withValues(alpha: .18), size: 110)),
          const Center(child: Icon(Icons.auto_awesome, color: Colors.white, size: 54)),
          Positioned(left: 12, bottom: 12, child: NexoraGlass(variant: GlassVariant.clear, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), child: const Row(children: [Icon(Icons.image_outlined, size: 14), SizedBox(width: 5), Text('NEXORA MOMENTS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800))]))),
        ]))),
      const SizedBox(height: 9),
      Row(children: [
        _ActionIcon(icon: isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? NexoraColors.like : null, label: likes, onTap: onLike),
        const SizedBox(width: 15), _ActionIcon(icon: Icons.mode_comment_outlined, label: comments, onTap: onComment),
        const SizedBox(width: 15), _ActionIcon(icon: Icons.send_outlined, label: 'مشاركة', onTap: onShare),
        const Spacer(), IconButton(onPressed: onSave, icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? NexoraColors.amber : NexoraColors.textMuted)),
      ]),
      const Divider(color: NexoraColors.hairline, height: 1),
    ]),
  );
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.label, required this.onTap, this.color});
  final IconData icon; final String label; final VoidCallback onTap; final Color? color;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      Icon(icon, size: 20, color: color ?? NexoraColors.textMuted), const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: NexoraColors.textMuted)),
    ]),
  ));
}

class _ExplorePreview extends StatefulWidget {
  const _ExplorePreview({required this.onOpen});
  final ValueChanged<String> onOpen;
  @override
  State<_ExplorePreview> createState() => _ExplorePreviewState();
}
class _ExplorePreviewState extends State<_ExplorePreview> {
  String _category = 'لك';
  final _search = TextEditingController();
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
    SliverToBoxAdapter(child: _PageHeader(title: 'استكشف', subtitle: 'اكتشف أشخاصًا وأفكارًا جديدة')),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(controller: _search, onSubmitted: (v) => widget.onOpen('نتائج البحث عن: $v'), decoration: InputDecoration(hintText: 'ابحث عن أشخاص أو منشورات أو هاشتاجات', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: () => widget.onOpen('البحث الصوتي — معاينة'), icon: const Icon(Icons.mic_none)), filled: true, fillColor: NexoraColors.surfaceRaised, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))))),
    SliverToBoxAdapter(
      child: SizedBox(
        height: 62,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: ['لك', 'الأشخاص', 'فيديو', 'مجتمعات', 'قريب منك']
              .map((v) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(v),
                      selected: _category == v,
                      onSelected: (_) => setState(() => _category = v),
                    ),
                  ))
              .toList(),
        ),
      ),
    ),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18, 4, 18, 12), child: Row(children: [const Text('رائج الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const Spacer(), TextButton(onPressed: () => widget.onOpen('كل الترندات'), child: const Text('عرض الكل'))]))),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Wrap(spacing: 8, runSpacing: 8, children: ['#NEXORA','#تصوير','#تقنية','#يوميات','#موسيقى'].map((tag) => ActionChip(avatar: const Icon(Icons.trending_up, size: 15, color: NexoraColors.cyan), label: Text(tag), onPressed: () => widget.onOpen('الهاشتاج $tag'))).toList()))),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18, 22, 18, 12), child: const Text('اكتشف المحتوى', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
    SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverGrid.count(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .82, children: const [
      _ExploreTile(title: 'لحظات ملهمة', subtitle: '12.8K منشور', colors: [Color(0xFF5632A3), Color(0xFF182F68)], icon: Icons.auto_awesome),
      _ExploreTile(title: 'مجتمع التقنية', subtitle: '8.2K عضو', colors: [Color(0xFF116B78), Color(0xFF172D4D)], icon: Icons.devices),
      _ExploreTile(title: 'فيديوهات اليوم', subtitle: 'ترند', colors: [Color(0xFF9B3D73), Color(0xFF41205D)], icon: Icons.play_circle),
      _ExploreTile(title: 'تصوير الشوارع', subtitle: '3.1K منشور', colors: [Color(0xFF94602C), Color(0xFF442D57)], icon: Icons.camera_alt),
    ])),
    const SliverToBoxAdapter(child: SizedBox(height: 112)),
  ]);
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({required this.title, required this.subtitle, required this.colors, required this.icon});
  final String title, subtitle; final List<Color> colors; final IconData icon;
  @override
  Widget build(BuildContext context) => InkWell(onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title — معاينة'))), borderRadius: BorderRadius.circular(20),
    child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors)), padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Icon(icon, color: Colors.white, size: 32),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)), Text(subtitle, style: const TextStyle(color: Color(0xFFDDDBEE), fontSize: 11))]),
    ])));
}

class _CreateLanding extends StatelessWidget {
  const _CreateLanding({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 20, 18, 120), children: [
    const _PageHeader(title: 'أنشئ', subtitle: 'حوّل أفكارك إلى محتوى يراه العالم'),
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF392078), Color(0xFF153C60)])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.white), SizedBox(height: 20),
      Text('قصتك تستحق أن تُروى', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
      SizedBox(height: 6), Text('شارك صورة أو فكرة أو لحظة قصيرة مع مجتمع NEXORA.', style: TextStyle(color: Color(0xFFE4E2F4), height: 1.5)),
    ])),
    const SizedBox(height: 18),
    _FeatureRow(icon: Icons.article_outlined, title: 'منشور', subtitle: 'نصوص وصور وألبومات', onTap: onCreate),
    _FeatureRow(icon: Icons.auto_awesome, title: 'قصة', subtitle: 'شارك لحظة لمدة 24 ساعة', onTap: onCreate),
    _FeatureRow(icon: Icons.video_collection_outlined, title: 'فيديو قصير', subtitle: 'أفكارك في مقطع سريع', onTap: onCreate),
    _FeatureRow(icon: Icons.poll_outlined, title: 'استطلاع', subtitle: 'اجمع آراء مجتمعك', onTap: onCreate),
  ]);
}

class _ChatListPreview extends StatelessWidget {
  const _ChatListPreview({required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 120), children: [
    const _PageHeader(title: 'الرسائل', subtitle: 'محادثاتك في مكان واحد'),
    TextField(decoration: InputDecoration(hintText: 'ابحث في المحادثات', prefixIcon: const Icon(Icons.search), filled: true, fillColor: NexoraColors.surfaceRaised, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))),
    const SizedBox(height: 18),
    _ChatRow(name: 'Mira Hassan', message: 'وصلت البيت؟', time: 'الآن', unread: 2, color: NexoraColors.pink, onTap: onOpen),
    _ChatRow(name: 'Omar Adel', message: 'بعتلك الصور', time: '10:42', unread: 0, color: NexoraColors.cyan, onTap: onOpen),
    _ChatRow(name: 'NEXORA Creators', message: 'Sara: صباح الخير للجميع', time: 'أمس', unread: 4, color: NexoraColors.violet, onTap: onOpen),
    _ChatRow(name: 'Family Group', message: 'أحمد: تمام ❤️', time: 'أمس', unread: 0, color: NexoraColors.amber, onTap: onOpen),
    const SizedBox(height: 18),
    OutlinedButton.icon(onPressed: onOpen, icon: const Icon(Icons.add_comment_outlined), label: const Text('محادثة جديدة')),
  ]);
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.name, required this.message, required this.time, required this.unread, required this.color, required this.onTap});
  final String name, message, time; final int unread; final Color color; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 5), onTap: onTap,
    leading: CircleAvatar(radius: 25, backgroundColor: color.withValues(alpha: .18), child: Icon(Icons.person, color: color)),
    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(message, style: const TextStyle(color: NexoraColors.textMuted)),
    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(time, style: const TextStyle(fontSize: 10, color: NexoraColors.textMuted)), if (unread > 0) ...[const SizedBox(height: 5), CircleAvatar(radius: 9, backgroundColor: NexoraColors.violet, child: Text('$unread', style: const TextStyle(fontSize: 10, color: Colors.white)))]]));
}

class _ChatPreviewScreen extends StatefulWidget {
  const _ChatPreviewScreen();
  @override
  State<_ChatPreviewScreen> createState() => _ChatPreviewScreenState();
}
class _ChatPreviewScreenState extends State<_ChatPreviewScreen> {
  final _controller = TextEditingController();
  final List<String> _messages = ['أهلًا! نورت NEXORA 👋', 'عامل إيه؟'];
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  void _send() { final text = _controller.text.trim(); if (text.isEmpty) return; setState(() { _messages.add(text); _controller.clear(); }); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Mira Hassan'), actions: [IconButton(onPressed: () => _demo('مكالمة صوتية'), icon: const Icon(Icons.call_outlined)), IconButton(onPressed: () => _demo('مكالمة فيديو'), icon: const Icon(Icons.videocam_outlined))]),
    body: Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        for (int i = 0; i < _messages.length; i++) Align(alignment: i.isEven ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd, child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(13), constraints: const BoxConstraints(maxWidth: 280), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: i.isOdd ? const LinearGradient(colors: NexoraColors.coolGradient) : null, color: i.isEven ? NexoraColors.surfaceRaised : null), child: Text(_messages[i], style: TextStyle(color: i.isOdd ? Colors.white : NexoraColors.text)))),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), child: Row(children: [
        IconButton(onPressed: () => _demo('إرفاق ملف'), icon: const Icon(Icons.attach_file)),
        Expanded(child: TextField(controller: _controller, onSubmitted: (_) => _send(), decoration: InputDecoration(hintText: 'اكتب رسالة...', filled: true, fillColor: NexoraColors.surfaceRaised, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
        const SizedBox(width: 8), IconButton.filled(onPressed: _send, icon: const Icon(Icons.send_rounded)),
      ])),
    ]));
  void _demo(String feature) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature — معاينة فقط')));
}

class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({required this.onPremium, required this.onOpen});
  final VoidCallback onPremium; final ValueChanged<String> onOpen;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 120), children: [
    _PageHeader(title: 'ملفي الشخصي', subtitle: 'هويتك ومساحتك الخاصة', action: IconButton(onPressed: () => onOpen('الإعدادات — معاينة'), icon: const Icon(Icons.settings_outlined))),
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF292052), Color(0xFF101C2B)])), child: Column(children: [
      Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: NexoraColors.brandGradient)), child: const CircleAvatar(radius: 42, backgroundColor: Color(0xFF282438), child: Icon(Icons.person, size: 45, color: Colors.white))),
      const SizedBox(height: 12), const Text('NEXORA Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const Text('@nexora.member', style: TextStyle(color: NexoraColors.textMuted)),
      const SizedBox(height: 10), const Text('أشارك أفكاري ولحظاتي مع العالم.', textAlign: TextAlign.center, style: TextStyle(color: NexoraColors.textMuted)),
      const SizedBox(height: 18), const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _Stat(value: '128', label: 'منشور'), _Stat(value: '2.4K', label: 'متابع'), _Stat(value: '384', label: 'أتابع'),
      ]),
      const SizedBox(height: 16), Row(children: [Expanded(child: FilledButton(onPressed: () => onOpen('تعديل الملف الشخصي'), child: const Text('تعديل الملف'))), const SizedBox(width: 8), OutlinedButton(onPressed: () => onOpen('مشاركة الملف الشخصي'), child: const Icon(Icons.ios_share))]),
    ])),
    const SizedBox(height: 16),
    _PremiumBanner(onTap: onPremium),
    const SizedBox(height: 16),
    _FeatureRow(icon: Icons.card_giftcard, title: 'الهدايا الرقمية', subtitle: 'أرسل دعمك لصناع المحتوى', onTap: () => onOpen('الهدايا الرقمية — معاينة')),
    _FeatureRow(icon: Icons.insights_outlined, title: 'استوديو صانع المحتوى', subtitle: 'الأداء والتحليلات والأرباح', onTap: () => onOpen('استوديو صانع المحتوى — معاينة')),
    _FeatureRow(icon: Icons.storefront_outlined, title: 'متجر NEXORA', subtitle: 'منتجات واشتراكات', onTap: () => onOpen('المتجر — معاينة')),
    _FeatureRow(icon: Icons.shield_outlined, title: 'الخصوصية والأمان', subtitle: 'تحكم في ظهورك وبياناتك', onTap: () => onOpen('الخصوصية والأمان — معاينة')),
    _FeatureRow(icon: Icons.palette_outlined, title: 'المظهر والثيمات', subtitle: 'اختر ألوان تجربتك', onTap: () => onOpen('الثيمات — معاينة')),
  ]);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: NexoraColors.textMuted, fontSize: 11))]);
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(22), child: Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF5735A5), Color(0xFFB34C91), Color(0xFFB9783F)])), child: Row(children: [
    const Icon(Icons.diamond_outlined, size: 34, color: Colors.white), const SizedBox(width: 12),
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NEXORA PLUS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)), Text('افتح مزايا وتجربة أكثر تخصيصًا', style: TextStyle(color: Colors.white70, fontSize: 11))])),
    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
  ])));
}

class NexoraPremiumPreviewScreen extends StatelessWidget {
  const NexoraPremiumPreviewScreen({super.key});
  void _preview(BuildContext context, String feature) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature: واجهة تجريبية فقط، لم يتم تحصيل أي مبلغ.')));
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('NEXORA PLUS'), actions: [const Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Center(child: Text('PREVIEW', style: TextStyle(color: NexoraColors.amber, fontSize: 10, fontWeight: FontWeight.w900))))]),
    body: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 28), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF6D49C9), Color(0xFFB54E91), Color(0xFFB7793E)])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.diamond, color: Colors.white, size: 38), SizedBox(height: 18),
        Text('ارتقِ بتجربتك.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        Text('NEXORA PLUS', style: TextStyle(letterSpacing: 2, color: Colors.white70, fontWeight: FontWeight.w800)),
        SizedBox(height: 10), Text('مزايا إضافية، تخصيص أوسع، وأدوات أكثر لصناع المحتوى.', style: TextStyle(color: Colors.white, height: 1.5)),
      ])),
      const SizedBox(height: 22), const Text('اختر خطتك', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      _PlanCard(name: 'شهري', price: 'السعر يحدد عند الربط', detail: 'مرونة شهر بشهر', onTap: () => _preview(context, 'الاشتراك الشهري')),
      const SizedBox(height: 10), _PlanCard(name: 'سنوي', price: 'السعر يحدد عند الربط', detail: 'خطة سنوية — تصميم العرض جاهز', featured: true, onTap: () => _preview(context, 'الاشتراك السنوي')),
      const SizedBox(height: 22), const Text('مزايا العضوية', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      const _Benefit(icon: Icons.palette_outlined, title: 'ثيمات وهوية موسعة', detail: 'ألوان وتأثيرات إضافية للملف الشخصي'),
      const _Benefit(icon: Icons.verified_outlined, title: 'خيارات توثيق متقدمة', detail: 'التوثيق الحقيقي يظل خاضعًا للمراجعة'),
      const _Benefit(icon: Icons.insights_outlined, title: 'تحليلات أعمق', detail: 'فهم أداء المحتوى والجمهور'),
      const _Benefit(icon: Icons.cloud_upload_outlined, title: 'مساحة وسائط إضافية', detail: 'السعة الفعلية حسب خطة التخزين'),
      const _Benefit(icon: Icons.support_agent, title: 'دعم أولوية', detail: 'قناة دعم مخصصة عند توفرها'),
      const SizedBox(height: 18), const Text('مزايا مدفوعة أخرى — معاينة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      _CommerceTile(icon: Icons.card_giftcard, title: 'الهدايا الرقمية', detail: 'إرسال هدايا ودعم المبدعين', onTap: () => _preview(context, 'الهدايا الرقمية')),
      _CommerceTile(icon: Icons.rocket_launch_outlined, title: 'ترويج المنشورات', detail: 'زيادة الوصول بإعلانات مدفوعة', onTap: () => _preview(context, 'ترويج المنشورات')),
      _CommerceTile(icon: Icons.campaign_outlined, title: 'إعلانات الأعمال', detail: 'إنشاء وإدارة الحملات الإعلانية', onTap: () => _preview(context, 'منصة الإعلانات')),
      _CommerceTile(icon: Icons.storefront_outlined, title: 'المتجر', detail: 'منتجات وطلبات واشتراكات', onTap: () => _preview(context, 'المتجر')),
      const SizedBox(height: 14),
      const Text('تنبيه: هذه شاشة عرض للتصميم وتجربة التنقل فقط. لا توجد بوابة دفع متصلة ولا يتم تحصيل أموال أو تفعيل اشتراكات حقيقية.', style: TextStyle(color: NexoraColors.textMuted, fontSize: 12, height: 1.6)),
    ]),
  ));
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.name, required this.price, required this.detail, required this.onTap, this.featured = false});
  final String name, price, detail; final VoidCallback onTap; final bool featured;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: NexoraColors.surfaceRaised, borderRadius: BorderRadius.circular(20), border: Border.all(color: featured ? NexoraColors.violet : NexoraColors.hairline, width: featured ? 1.5 : 1)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const Spacer(), if (featured) const Chip(label: Text('موصى بها'), visualDensity: VisualDensity.compact)]),
    const SizedBox(height: 4), Text(price, style: const TextStyle(color: NexoraColors.cyan, fontWeight: FontWeight.w700)), Text(detail, style: const TextStyle(color: NexoraColors.textMuted, fontSize: 12)),
    const SizedBox(height: 12), SizedBox(width: double.infinity, child: featured ? FilledButton(onPressed: onTap, child: const Text('جرّب شكل الاشتراك')) : OutlinedButton(onPressed: onTap, child: const Text('عرض الخطة'))),
  ]));
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.detail});
  final IconData icon; final String title, detail;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: NexoraColors.violet.withValues(alpha: .16), child: Icon(icon, color: NexoraColors.violet)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(detail, style: const TextStyle(color: NexoraColors.textMuted, fontSize: 11)));
}

class _CommerceTile extends StatelessWidget {
  const _CommerceTile({required this.icon, required this.title, required this.detail, required this.onTap});
  final IconData icon; final String title, detail; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), tileColor: NexoraColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), leading: Icon(icon, color: NexoraColors.amber), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(detail, style: const TextStyle(color: NexoraColors.textMuted, fontSize: 11)), trailing: const Icon(Icons.chevron_left));
}

class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet({required this.title, required this.child});
  final String title; final Widget child;
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Container(
    padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.viewInsetsOf(context).bottom + 24),
    decoration: const BoxDecoration(color: Color(0xFF101018), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(9)))),
      const SizedBox(height: 18), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12), child,
    ])),
  ));
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(onTap: onTap, contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: NexoraColors.violet.withValues(alpha: .17), child: Icon(icon, color: NexoraColors.violet)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle, style: const TextStyle(color: NexoraColors.textMuted, fontSize: 11)));
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(onTap: onTap, contentPadding: const EdgeInsets.symmetric(vertical: 4), leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: NexoraColors.surfaceRaised, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: NexoraColors.cyan)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle, style: const TextStyle(color: NexoraColors.textMuted, fontSize: 11)), trailing: const Icon(Icons.chevron_left, color: NexoraColors.textFaint));
}
