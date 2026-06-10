import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/common/wasl_button.dart';
import '../../widgets/common/wasl_shake_widget.dart';
import '../../widgets/common/wasl_toast.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<WaslShakeWidgetState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();

  static const List<double> _quickAmounts = [100, 200, 300, 500];

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _shakeKey.currentState?.shake();
      return;
    }
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    if (auth.uid == null) return;

    await wallet.submitTopUp(
      driverId: auth.uid!,
      amount: double.parse(_amountController.text.trim()),
      reference: _referenceController.text.trim(),
    );

    if (!mounted) return;
    if (wallet.topUpSubmitted) {
      _showSuccessDialog();
    } else if (wallet.error != null) {
      WaslToast.show(context, wallet.error!, type: ToastType.error);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 52),
            )
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text('تم إرسال الطلب!',
                style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'سيتم تأكيد الشحن من قِبل الإدارة خلال 24 ساعة. تابع من تبويب الشحنات.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            WaslButton(
              label: 'العودة للمحفظة',
              onPressed: () {
                context.read<WalletProvider>().resetTopUpState();
                Navigator.of(context).pop();
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('شحن المحفظة', style: AppTextStyles.h3),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: AppColors.info.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.info, size: 20),
                        const SizedBox(width: 8),
                        Text('كيف تشحن؟',
                            style: AppTextStyles.bodyLarge
                                .copyWith(color: AppColors.info)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StepRow(
                        number: '١',
                        text:
                            'قم بإيداع المبلغ عبر CashPlus أو Wafacash على رقم الإدارة'),
                    const SizedBox(height: 8),
                    _StepRow(
                        number: '٢',
                        text: 'احتفظ برقم مرجع المعاملة'),
                    const SizedBox(height: 8),
                    _StepRow(
                        number: '٣',
                        text:
                            'أدخل البيانات أدناه — ستؤكد الإدارة خلال 24 ساعة'),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.05, end: 0),

              const SizedBox(height: 28),

              // Amount label
              Text('المبلغ (درهم)', style: AppTextStyles.label),
              const SizedBox(height: 10),

              // Quick-select chips
              Row(
                children: _quickAmounts.map((amt) {
                  final selected =
                      _amountController.text == amt.toInt().toString();
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _amountController.text = amt.toInt().toString()),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.25),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          '${amt.toInt()}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                style: AppTextStyles.body,
                decoration: const InputDecoration(
                  hintText: 'أو أدخل مبلغاً مخصصاً',
                  prefixIcon:
                      Icon(Icons.payments_rounded, color: AppColors.primary),
                  suffixText: 'درهم',
                ),
                validator: Validators.walletTopUp,
              )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 22),

              // Reference
              Text('رقم المرجع', style: AppTextStyles.label),
              const SizedBox(height: 10),
              TextFormField(
                controller: _referenceController,
                style: AppTextStyles.body,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'مثال: REF-12345678',
                  prefixIcon: Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'رقم المرجع مطلوب';
                  }
                  return null;
                },
              )
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // Contact admin reminder
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'هل لديك سؤال؟ تواصل مع الإدارة عبر واتساب لتأكيد الإيداع.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              WaslShakeWidget(
                key: _shakeKey,
                child: WaslButton(
                  label: 'إرسال الطلب',
                  onPressed: _submit,
                  isLoading: wallet.isLoading,
                  icon: Icons.send_rounded,
                ),
              )
                  .animate(delay: 250.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;
  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.info,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppTextStyles.bodySecondary),
        ),
      ],
    );
  }
}
