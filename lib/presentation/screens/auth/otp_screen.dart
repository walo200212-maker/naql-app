import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/wasl_button.dart';
import '../../widgets/common/wasl_toast.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  bool _hasError = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    if (_otp.length < 6) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(_otp);
    if (!mounted) return;
    if (!success) {
      setState(() => _hasError = true);
      WaslToast.show(context, 'الرمز غير صحيح. حاول مجدداً.', type: ToastType.error);
      return;
    }
    try {
      await auth.loadCurrentUserProfile();
    } catch (_) {}
    if (!mounted) return;
    if (auth.user == null) {
      context.go(AppRoutes.userTypeSelect);
    } else if (auth.user!.type == AppConstants.userTypeDriver) {
      context.go(AppRoutes.driverHome);
    } else {
      context.go(AppRoutes.clientHome);
    }
  }

  Future<void> _resend() async {
    if (_countdown > 0) return;
    await context.read<AuthProvider>().sendOtp(widget.phoneNumber);
    _startTimer();
    if (mounted) {
      WaslToast.show(context, 'تم إرسال رمز جديد', type: ToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Lock icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.lock_open_rounded,
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
                'أدخل الرمز',
                style: GoogleFonts.cairo(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),

              RichText(
                text: TextSpan(
                  text: 'تم إرسال رمز التحقق إلى  ',
                  style: AppTextStyles.bodySecondary,
                  children: [
                    TextSpan(
                      text: widget.phoneNumber,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 48),

              // OTP boxes
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: _hasError
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.errorGlow,
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      )
                    : null,
                child: PinCodeTextField(
                  appContext: context,
                  length: 6,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.scale,
                  animationDuration: const Duration(milliseconds: 200),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(14),
                    fieldHeight: 60,
                    fieldWidth: 48,
                    activeColor: _hasError ? AppColors.error : AppColors.primary,
                    inactiveColor: _hasError ? AppColors.errorGlow : AppColors.surfaceBorder,
                    selectedColor: AppColors.primary,
                    activeFillColor: _hasError
                        ? AppColors.errorGlow
                        : AppColors.surfaceVariant,
                    inactiveFillColor: AppColors.surfaceHigh,
                    selectedFillColor: AppColors.surfaceVariant,
                  ),
                  enableActiveFill: true,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  onChanged: (v) => setState(() {
                    _otp = v;
                    _hasError = false;
                  }),
                  onCompleted: (_) => _verify(),
                  cursorColor: AppColors.primary,
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms),

              if (_hasError) ...[
                const SizedBox(height: 8),
                Text(
                  'الرمز غير صحيح، تحقق منه وحاول مجدداً',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                )
                    .animate()
                    .shakeX(hz: 4, amount: 6),
              ],

              const SizedBox(height: 36),

              WaslButton(
                label: 'تحقق',
                isLoading: auth.isLoading,
                onPressed: _otp.length == 6 ? _verify : null,
                icon: Icons.check_rounded,
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // Resend countdown
              Center(
                child: _countdown > 0
                    ? RichText(
                        text: TextSpan(
                          text: 'إعادة الإرسال بعد  ',
                          style: AppTextStyles.bodySecondary,
                          children: [
                            TextSpan(
                              text: '${_countdown}s',
                              style: AppTextStyles.bodySecondary.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: _resend,
                        child: Text(
                          'إعادة إرسال الرمز',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
