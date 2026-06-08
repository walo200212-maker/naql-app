import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/naql_button.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  bool _hasError = false;

  Future<void> _verify() async {
    if (_otp.length < 6) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(_otp);
    if (!mounted) return;
    if (!success) {
      setState(() => _hasError = true);
      return;
    }
    await auth.loadCurrentUserProfile();
    if (!mounted) return;
    if (auth.user == null) {
      context.go(AppRoutes.userTypeSelect);
    } else if (auth.user!.type == AppConstants.userTypeDriver) {
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
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Text('Vérification', style: AppTextStyles.display)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),

              RichText(
                text: TextSpan(
                  text: 'Code envoyé au ',
                  style: AppTextStyles.bodySecondary,
                  children: [
                    TextSpan(
                      text: widget.phoneNumber,
                      style: AppTextStyles.bodySecondary.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 48),

              PinCodeTextField(
                appContext: context,
                length: 6,
                keyboardType: TextInputType.number,
                animationType: AnimationType.scale,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeColor: _hasError ? AppColors.error : AppColors.primary,
                  inactiveColor: _hasError ? AppColors.error : AppColors.border,
                  selectedColor: AppColors.primary,
                  activeFillColor: AppColors.surfaceVariant,
                  inactiveFillColor: AppColors.surfaceVariant,
                  selectedFillColor: AppColors.surfaceVariant,
                ),
                enableActiveFill: true,
                textStyle: AppTextStyles.h3,
                onChanged: (v) => setState(() {
                  _otp = v;
                  _hasError = false;
                }),
                onCompleted: (_) => _verify(),
                cursorColor: AppColors.primary,
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms),

              if (_hasError) ...[
                const SizedBox(height: 8),
                Text(
                  'Code incorrect. Réessayez.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ],

              const SizedBox(height: 32),

              NaqlButton(
                label: 'Vérifier',
                isLoading: auth.isLoading,
                onPressed: _otp.length == 6 ? _verify : null,
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: () =>
                      context.read<AuthProvider>().sendOtp(widget.phoneNumber),
                  child: Text('Renvoyer le code',
                      style:
                          AppTextStyles.body.copyWith(color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
