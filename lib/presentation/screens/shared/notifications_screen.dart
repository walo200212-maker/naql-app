import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Placeholder data — replace with real Firestore stream when push is wired
  static const List<_NotifData> _items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('الإشعارات', style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () {},
              child: Text('مسح الكل',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.primary)),
            ),
        ],
      ),
      body: _items.isEmpty ? _EmptyState() : _NotifList(items: _items),
    );
  }
}

class _NotifData {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String time;
  const _NotifData(
      {required this.title,
      required this.body,
      required this.icon,
      required this.color,
      required this.time});
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 48, color: AppColors.textHint),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text('لا توجد إشعارات', style: AppTextStyles.h3)
              .animate(delay: 100.ms)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'ستظهر إشعاراتك هنا',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          )
              .animate(delay: 160.ms)
              .fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

// ─── Notification list ────────────────────────────────────────────────────────

class _NotifList extends StatelessWidget {
  final List<_NotifData> items;
  const _NotifList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 3),
                    Text(item.body, style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(item.time, style: AppTextStyles.caption),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: i * 50))
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, end: 0);
      },
    );
  }
}
