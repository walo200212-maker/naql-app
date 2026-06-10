import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../widgets/common/wasl_button.dart';

class PermissionsScreen extends StatefulWidget {
  final String role; // 'client' or 'driver'
  const PermissionsScreen({super.key, required this.role});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _notificationsGranted = false;
  bool _locationGranted = false;

  Future<void> _requestNotifications() async {
    try {
      final status = await Permission.notification.request();
      if (mounted) setState(() => _notificationsGranted = status.isGranted);
    } catch (_) {
      if (mounted) setState(() => _notificationsGranted = true);
    }
  }

  Future<void> _requestLocation() async {
    try {
      final status = await Permission.location.request();
      if (mounted) setState(() => _locationGranted = status.isGranted);
    } catch (_) {
      if (mounted) setState(() => _locationGranted = true);
    }
  }

  void _continue() {
    if (widget.role == 'driver') {
      context.go(AppRoutes.driverRegistration);
    } else {
      context.go(AppRoutes.clientHome);
    }
  }

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
              // ── Icon ───────────────────────────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: AppColors.primary, size: 36),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 300.ms),

              const SizedBox(height: 24),

              Text(
                'نحتاج\nإذنك',
                style: GoogleFonts.cairo(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.12, end: 0),

              const SizedBox(height: 8),

              Text(
                'هذا يساعدنا على تقديم خدمة أفضل لك',
                style: AppTextStyles.bodySecondary,
              )
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 44),

              // ── Notifications ──────────────────────────────────────────────
              _PermCard(
                icon: Icons.notifications_active_rounded,
                title: 'الإشعارات',
                description: 'لنخطرك بتحديثات طلباتك فورياً',
                accentColor: AppColors.info,
                isGranted: _notificationsGranted,
                onAllow: _requestNotifications,
                delay: 200,
              ),

              const SizedBox(height: 16),

              // ── Location ───────────────────────────────────────────────────
              _PermCard(
                icon: Icons.location_on_rounded,
                title: 'الموقع',
                description: 'لعرض السائقين القريبين منك',
                accentColor: AppColors.success,
                isGranted: _locationGranted,
                onAllow: _requestLocation,
                delay: 300,
              ),

              const Spacer(),

              WaslButton(
                label: 'متابعة',
                onPressed: _continue,
                icon: Icons.arrow_forward_rounded,
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 8),

              Center(
                child: TextButton(
                  onPressed: _continue,
                  child: Text(
                    'تخطي في الوقت الحالي',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint),
                  ),
                ),
              )
                  .animate(delay: 450.ms)
                  .fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Permission card ────────────────────────────────────────────────────────────

class _PermCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final bool isGranted;
  final VoidCallback onAllow;
  final int delay;

  const _PermCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.isGranted,
    required this.onAllow,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGranted
              ? accentColor.withValues(alpha: 0.4)
              : AppColors.surfaceBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(description, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isGranted
                ? _GrantedChip(accentColor: accentColor)
                : _AllowButton(accentColor: accentColor, onTap: onAllow),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.12, end: 0);
  }
}

class _GrantedChip extends StatelessWidget {
  final Color accentColor;
  const _GrantedChip({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('granted'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, color: accentColor, size: 14),
          const SizedBox(width: 4),
          Text(
            'مسموح',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _AllowButton extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onTap;
  const _AllowButton({required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('allow'),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'السماح',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}
