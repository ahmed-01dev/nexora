import 'package:flutter/material.dart';

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXORA Reels', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_outline_rounded, size: 64),
              const SizedBox(height: 18),
              const Text(
                'الفيديوهات القصيرة جاية في مرحلة الوسائط',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                'مش هنعرض مقاطع وهمية. تشغيل الريلز هيتفعّل بعد تجهيز رفع الفيديو، المعالجة، الصور المصغرة، وسياسة المحتوى.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
