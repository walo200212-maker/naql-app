import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class WaslBottomNavItem {
  final IconData icon;
  final String label;

  const WaslBottomNavItem({required this.icon, required this.label});
}

const List<WaslBottomNavItem> waslBottomNavItems = [
  WaslBottomNavItem(icon: Icons.home_rounded, label: 'الرئيسية'),
  WaslBottomNavItem(icon: Icons.list_alt_rounded, label: 'طلباتي'),
  WaslBottomNavItem(icon: Icons.location_on_rounded, label: 'تتبع'),
  WaslBottomNavItem(icon: Icons.person_rounded, label: 'حسابي'),
];

/// Floating pill-shaped bottom navigation bar.
/// Active tab gets an orange pill background with orange icon + label;
/// inactive tabs show a muted icon + label. Adapts to light/dark theme.
class WaslBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<WaslBottomNavItem> items;

  const WaslBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = waslBottomNavItems,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;
    final inactiveIcon = isDark ? Colors.white54 : const Color(0xFF8A8A8A);
    final inactiveLabel = isDark ? Colors.white60 : const Color(0xFF6B6B6B);

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final selected = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: selected ? AppColors.primary : inactiveIcon,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color:
                              selected ? AppColors.primary : inactiveLabel,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
