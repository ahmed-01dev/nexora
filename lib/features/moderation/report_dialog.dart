import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  final String targetType;
  final String targetId;

  static Future<bool> show(
    BuildContext context, {
    required String targetType,
    required String targetId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ReportDialog(
        targetType: targetType,
        targetId: targetId,
      ),
    );
    return result == true;
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  static const Map<String, String> _reasons = {
    'harassment': 'مضايقة أو تنمر',
    'threats': 'تهديدات أو تحريض على العنف',
    'spam': 'رسائل مزعجة أو سبام',
    'scam': 'احتيال أو خداع',
    'impersonation': 'انتحال شخصية',
    'sexual_content': 'محتوى جنسي غير مسموح',
    'child_safety': 'مخاوف تتعلق بسلامة طفل',
    'dangerous_content': 'محتوى خطير',
    'illegal_content': 'محتوى غير قانوني',
    'copyright': 'انتهاك حقوق ملكية',
    'other': 'سبب آخر',
  };

  final _details = TextEditingController();
  String _reason = 'spam';
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('reports').insert({
        'reporter_id': uid,
        'target_type': widget.targetType,
        'target_id': widget.targetId,
        'reason': _reason,
        'details': _details.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'submit_report');
      if (mounted) {
        setState(() {
          _error = AppErrorService.message(error);
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.targetType == 'comment' ? 'الإبلاغ عن التعليق' : 'الإبلاغ عن المنشور'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اختر السبب الأقرب. البلاغ يذهب لفريق المراجعة ولا يظهر لصاحب المحتوى.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(labelText: 'سبب البلاغ'),
                items: _reasons.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: _sending
                    ? null
                    : (value) {
                        if (value != null) setState(() => _reason = value);
                      },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _details,
                maxLength: 2000,
                maxLines: 4,
                enabled: !_sending,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل إضافية (اختياري)',
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _sending ? null : () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('إرسال البلاغ'),
          ),
        ],
      );
}
