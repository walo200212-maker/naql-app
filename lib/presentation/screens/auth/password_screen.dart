import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/wasl_button.dart';
import '../../widgets/common/wasl_shake_widget.dart';
import '../../widgets/common/wasl_toast.dart';

class PasswordScreen extends StatefulWidget {
  final String email;
  const PasswordScreen({super.key, required this.email});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _shakeKey = GlobalKey<WaslShakeWidgetState>();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final password = _passwordCtrl.text.trim();
    if (password.length < 6) {
      _shakeKey.currentState?.shake();
      WaslToast.show(
          context, 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
          type: ToastType.error);
      return;
    }

    final auth = context.read<AuthProvider>();
    final error = await auth.signInOrCreateWithEmail(
      email: widget.email,
      password: password,
    );

    if (!mounted) return;

    if (error != null) {
      _shakeKey.currentState?.shake();
      WaslToast.show(context, error, type: ToastType.error);
      return;
    }

    try {
      await auth.loadCurrentUserProfile();
    } catch (_) {}
    if (!mounted) return;

    if (auth.user == null) {
      context.go(AppRoutes.userTypeSelect);
    } else if (auth.isDriver) {
      context.go(AppRoutes.driverHome);
    } else {
      context.go(AppRoutes.clientHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Lock icon ──────────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.lock_rounded,
                    color: AppColors.primary, size: 30),
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
                'كلمة المرور',
                style: GoogleFonts.cairo(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.15, end: 0),

              const SizedBox(height: 6),

              Text(
                widget.email,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textDirection: TextDirection.ltr,
              )
                  .animate(delay: 130.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 40),

              // ── Password field ─────────────────────────────────────────────
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: AppTextStyles.bodyLarge,
                textDirection: TextDirection.ltr,
                onEditingComplete: _onContinue,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.textSecondary, size: 22),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
              )
                  .animate(delay: 180.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 20),

              WaslShakeWidget(
                key: _shakeKey,
                child: WaslButton(
                  label: 'متابعة',
                  onPressed: auth.isLoading ? null : _onContinue,
                  isLoading: auth.isLoading,
                  icon: Icons.arrow_forward_rounded,
                ),
              )
                  .animate(delay: 240.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  'ليس لديك حساب؟ أدخل كلمة مرور جديدة وسنُنشئ لك حساباً',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              )
                  .animate(delay: 290.ms)
                  .fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
