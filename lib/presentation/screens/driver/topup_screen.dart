import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/common/naql_button.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(wallet.error!)),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
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
            Text('Demande envoyée !', style: AppTextStyles.h2,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Votre recharge sera confirmée par l\'admin dans les 24h. Vérifiez l\'onglet Recharges.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            NaqlButton(
              label: 'Retour au portefeuille',
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
      appBar: AppBar(title: const Text('Recharger le portefeuille')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.info, size: 20),
                        const SizedBox(width: 8),
                        Text('Comment recharger ?',
                            style: AppTextStyles.bodyLarge
                                .copyWith(color: AppColors.info)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _StepRow(
                        number: '1',
                        text:
                            'Effectuez un dépôt via CashPlus ou Wafacash au numéro admin'),
                    const SizedBox(height: 6),
                    _StepRow(
                        number: '2',
                        text:
                            'Notez le numéro de référence de la transaction'),
                    const SizedBox(height: 6),
                    _StepRow(
                        number: '3',
                        text:
                            'Remplissez ce formulaire — l\'admin confirmera sous 24h'),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.05, end: 0),

              const SizedBox(height: 28),

              // Amount
              Text('Montant (MAD)', style: AppTextStyles.label),
              const SizedBox(height: 8),

              // Quick-select chips
              Row(
                children: _quickAmounts.map((amt) {
                  final selected = _amountController.text == amt.toInt().toString();
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _amountController.text = amt.toInt().toString()),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                        ),
                        child: Text(
                          '${amt.toInt()}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: selected ? Colors.white : AppColors.textSecondary,
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
                  hintText: 'Ou saisir un montant personnalisé',
                  prefixIcon: Icon(Icons.payments_rounded,
                      color: AppColors.primary),
                  suffixText: 'MAD',
                ),
                validator: Validators.walletTopUp,
              )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 20),

              // Reference
              Text('Numéro de référence', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextFormField(
                controller: _referenceController,
                style: AppTextStyles.body,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Ex: REF-12345678',
                  prefixIcon:
                      Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Numéro de référence requis';
                  }
                  return null;
                },
              )
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 28),

              // Contact admin reminder
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Des questions ? Contactez l\'admin WhatsApp pour confirmer votre dépôt.',
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

              NaqlButton(
                label: 'Soumettre la demande',
                onPressed: _submit,
                isLoading: wallet.isLoading,
                icon: Icons.send_rounded,
              )
                  .animate(delay: 250.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 24),
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
          width: 20,
          height: 20,
          decoration: BoxDecoration(
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
