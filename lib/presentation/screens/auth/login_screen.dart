import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/naql_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+212');
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acceptez les conditions d\'utilisation')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    await auth.sendOtp(_phoneController.text.trim());
    if (!mounted) return;
    if (auth.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.error!)));
      auth.clearError();
    } else {
      context.push(AppRoutes.otp,
          extra: _phoneController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_shipping_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text('نقل',
                        style: AppTextStyles.h2.copyWith(
                            color: AppColors.primary)),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.1, end: 0),

                const SizedBox(height: 48),

                Text('Bienvenue 👋', style: AppTextStyles.display)
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Entrez votre numéro pour continuer',
                  style: AppTextStyles.bodySecondary,
                )
                    .animate(delay: 150.ms)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 40),

                // Phone field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    prefixIcon:
                        Icon(Icons.phone_rounded, color: AppColors.primary),
                    hintText: '+212 6XX XXX XXX',
                  ),
                  validator: Validators.phone,
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // Terms checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    Expanded(
                      child: Text(
                        'J\'accepte les conditions d\'utilisation',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ),
                  ],
                )
                    .animate(delay: 250.ms)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 32),

                NaqlButton(
                  label: S.sendOtp,
                  isLoading: auth.isLoading,
                  onPressed: _sendOtp,
                  icon: Icons.arrow_forward_rounded,
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // Divider with text
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou',
                          style: AppTextStyles.caption),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Driver sign-up hint
                Center(
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.driverRegistration),
                    child: RichText(
                      text: TextSpan(
                        text: 'Vous êtes chauffeur ? ',
                        style: AppTextStyles.bodySecondary,
                        children: [
                          TextSpan(
                            text: 'Inscrivez-vous ici',
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
      ),
    );
  }
}
