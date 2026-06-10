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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _shakeKey = GlobalKey<WaslShakeWidgetState>();
  final _inputCtrl = TextEditingController();

  bool get _isEmail => _inputCtrl.text.contains('@');

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final input = _inputCtrl.text.trim();
    if (input.isEmpty) {
      _shakeKey.currentState?.shake();
      return;
    }

    if (_isEmail) {
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(input)) {
        _shakeKey.currentState?.shake();
        WaslToast.show(context, 'أدخل بريداً إلكترونياً صحيحاً',
            type: ToastType.error);
        return;
      }
      context.push(AppRoutes.password, extra: input);
    } else {
      final cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(cleaned)) {
        _shakeKey.currentState?.shake();
        WaslToast.show(context, 'أدخل رقم هاتف صحيحاً',
            type: ToastType.error);
        return;
      }
      // Convert Moroccan local format to E.164 (+212XXXXXXXXX)
      String phone = cleaned;
      if (phone.startsWith('0') && phone.length == 10) {
        phone = '+212${phone.substring(1)}';
      } else if (!phone.startsWith('+')) {
        phone = '+$phone';
      }
      final auth = context.read<AuthProvider>();
      await auth.sendOtp(phone);
      if (!mounted) return;
      if (auth.error != null) {
        WaslToast.show(context, auth.error!, type: ToastType.error);
        auth.clearError();
      } else {
        context.push(AppRoutes.otp, extra: phone);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;
    if (!success) {
      if (auth.error != null) {
        WaslToast.show(context, auth.error!, type: ToastType.error);
        auth.clearError();
      }
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // ── Logo ───────────────────────────────────────────────────────
              Center(
                child: Image.asset(
                  'assets/images/waslapp_logoo.png',
                  width: 160,
                  fit: BoxFit.contain,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1)),

              const SizedBox(height: 48),

              // ── Heading ────────────────────────────────────────────────────
              Text(
                'تسجيل الدخول\nأو إنشاء حساب',
                style: GoogleFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.12, end: 0),

              const SizedBox(height: 6),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _isEmail
                      ? 'ستحتاج إلى كلمة مرور للمتابعة'
                      : 'أدخل رقم هاتفك أو بريدك الإلكتروني',
                  key: ValueKey(_isEmail),
                  style: AppTextStyles.bodySecondary,
                ),
              )
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // ── Input ──────────────────────────────────────────────────────
              TextField(
                controller: _inputCtrl,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                style: AppTextStyles.bodyLarge,
                onChanged: (_) => setState(() {}),
                onEditingComplete: _onContinue,
                decoration: InputDecoration(
                  hintText: 'رقم الهاتف أو البريد الإلكتروني',
                  prefixIcon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isEmail
                          ? Icons.email_outlined
                          : Icons.phone_outlined,
                      key: ValueKey(_isEmail),
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 16),

              // ── Continue button ────────────────────────────────────────────
              WaslShakeWidget(
                key: _shakeKey,
                child: WaslButton(
                  label: 'متابعة',
                  onPressed: auth.isLoading ? null : _onContinue,
                  isLoading: auth.isLoading,
                  icon: Icons.arrow_forward_rounded,
                ),
              )
                  .animate(delay: 260.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 36),

              // ── OR divider ─────────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('أو', style: AppTextStyles.caption),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              )
                  .animate(delay: 310.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // ── Google ─────────────────────────────────────────────────────
              _SocialButton(
                icon: _googleIcon(),
                label: 'المتابعة بـ Google',
                onPressed: auth.isLoading ? null : _signInWithGoogle,
              )
                  .animate(delay: 360.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 12),

              // ── Apple (coming soon) ────────────────────────────────────────
              Opacity(
                opacity: 0.38,
                child: _SocialButton(
                  icon: const Icon(Icons.apple,
                      color: AppColors.textPrimary, size: 22),
                  label: 'المتابعة بـ Apple',
                  onPressed: null,
                  trailing: _comingSoonChip(),
                ),
              )
                  .animate(delay: 410.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 52),
            ],
          ),
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }

  Widget _comingSoonChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceBorder,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'قريباً',
        style: AppTextStyles.caption.copyWith(fontSize: 10),
      ),
    );
  }
}

// ── Reusable social button ─────────────────────────────────────────────────────

class _SocialButton extends StatefulWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final Widget? trailing;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.trailing,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
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
        if (widget.onPressed != null) _ctrl.reverse();
      },
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.icon,
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
