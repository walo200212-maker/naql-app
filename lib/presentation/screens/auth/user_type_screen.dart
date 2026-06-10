import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';

class UserTypeScreen extends StatelessWidget {
  const UserTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'كيف تريد\nالبدء؟',
                style: GoogleFonts.cairo(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.15, end: 0),

              const SizedBox(height: 8),

              Text(
                'اختر نوع حسابك',
                style: AppTextStyles.bodySecondary,
              )
                  .animate(delay: 80.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 40),

              // Client card
              Expanded(
                child: _HeroCard(
                  icon: Icons.person_rounded,
                  label: 'أنا عميل',
                  description: 'أبحث عن سائق لنقل أغراضي',
                  accentColor: AppColors.info,
                  delay: 160,
                  onTap: () => context.go(AppRoutes.permissions, extra: 'client'),
                ),
              ),

              const SizedBox(height: 16),

              // Driver card
              Expanded(
                child: _HeroCard(
                  icon: Icons.local_shipping_rounded,
                  label: 'أنا سائق',
                  description: 'عندي شاحنة وأريد العمل',
                  accentColor: AppColors.primary,
                  delay: 260,
                  onTap: () => context.go(AppRoutes.permissions, extra: 'driver'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color accentColor;
  final int delay;
  final VoidCallback onTap;

  const _HeroCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.accentColor,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _ctrl.reverse();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _ctrl.forward();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _ctrl.forward();
      },
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          decoration: BoxDecoration(
            color: _pressed
                ? widget.accentColor.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _pressed
                  ? widget.accentColor
                  : AppColors.surfaceBorder,
              width: 1.5,
            ),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.18),
                      blurRadius: 32,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.accentColor,
                    size: 30,
                  ),
                ),

                // Text + arrow
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.description,
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.12, end: 0);
  }
}
