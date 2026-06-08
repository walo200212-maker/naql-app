import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/offer_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/naql_button.dart';
import '../../widgets/common/status_badge.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _firestore = FirestoreService();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  JobModel? _job;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _offerSubmitted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadJob() async {
    try {
      _firestore.watchJob(widget.jobId).listen((job) {
        if (mounted) setState(() { _job = job; _isLoading = false; });
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  double get _enteredPrice {
    final v = double.tryParse(_priceController.text.trim());
    return v ?? 0;
  }

  double get _commission => _enteredPrice * AppConstants.commissionRate;

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_job == null) return;
    final auth = context.read<AuthProvider>();
    if (auth.uid == null) return;
    final driver = auth.driver;
    if (driver == null) return;

    // Guard: check wallet
    if (!driver.canAcceptJobs) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Solde insuffisant pour faire une offre')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _firestore.submitOffer(OfferModel(
        id: '',
        jobId: widget.jobId,
        driverId: auth.uid!,
        totalPrice: _enteredPrice,
        status: AppConstants.offerStatusPending,
        createdAt: DateTime.now(),
      ));
      if (mounted) setState(() { _offerSubmitted = true; _isSubmitting = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_job == null || _error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Détail mission')),
        body: Center(
          child: Text(_error ?? 'Mission introuvable',
              style: AppTextStyles.bodySecondary),
        ),
      );
    }

    final job = _job!;
    final auth = context.watch<AuthProvider>();
    final driver = auth.driver;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail de la mission'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusBadge(status: job.status),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route card
            _RouteCard(job: job)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            // Details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    icon: Icons.straighten_rounded,
                    label: 'Distance',
                    value: '${job.distanceKm.toStringAsFixed(1)} km',
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    icon: Icons.location_city_rounded,
                    label: 'Ville',
                    value: job.city,
                  ),
                  if (job.isIntercity) ...[
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Type',
                      value: 'Intercity',
                      valueColor: AppColors.info,
                    ),
                  ],
                  if (job.itemsDescription.isNotEmpty) ...[
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.inventory_2_rounded,
                      label: 'Description',
                      value: job.itemsDescription,
                    ),
                  ],
                ],
              ),
            )
                .animate(delay: 80.ms)
                .fadeIn(duration: 400.ms),

            // Photos
            if (job.itemsPhotos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Photos des articles', style: AppTextStyles.label),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: job.itemsPhotos.length,
                  itemBuilder: (_, i) => Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(job.itemsPhotos[i]),
                        fit: BoxFit.cover,
                      ),
                      color: AppColors.surfaceVariant,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Offer section
            if (job.status == AppConstants.jobStatusOpen) ...[
              if (_offerSubmitted)
                _OfferSentBanner()
              else
                _OfferForm(
                  formKey: _formKey,
                  priceController: _priceController,
                  commission: _commission,
                  driverWallet: driver?.walletBalance ?? 0,
                  isSubmitting: _isSubmitting,
                  onChanged: () => setState(() {}),
                  onSubmit: _submitOffer,
                ),
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      'Cette mission n\'est plus disponible pour les offres.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final JobModel job;
  const _RouteCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Itinéraire', style: AppTextStyles.label),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline dots
              Column(
                children: [
                  const Icon(Icons.circle, color: AppColors.success, size: 12),
                  Container(
                    width: 2,
                    height: 40,
                    color: AppColors.border,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 16),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Départ', style: AppTextStyles.caption),
                    Text(
                      job.pickupLocation.address,
                      style: AppTextStyles.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    Text('Arrivée', style: AppTextStyles.caption),
                    Text(
                      job.dropoffLocation.address,
                      style: AppTextStyles.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.bodySecondary),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(color: valueColor),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _OfferForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController priceController;
  final double commission;
  final double driverWallet;
  final bool isSubmitting;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  const _OfferForm({
    required this.formKey,
    required this.priceController,
    required this.commission,
    required this.driverWallet,
    required this.isSubmitting,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final walletAfter = driverWallet - commission;
    final willBeBlocked = walletAfter < AppConstants.minWalletBalance;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Soumettre votre offre', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            'Le client verra votre prix et choisira le meilleur chauffeur.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: priceController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.price.copyWith(fontSize: 22),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0',
              prefixText: 'MAD  ',
              suffixText: '  total',
            ),
            onChanged: (_) => onChanged(),
            validator: (v) {
              final n = double.tryParse(v?.trim() ?? '');
              if (n == null || n <= 0) return 'Entrez un prix valide';
              if (n < 50) return 'Prix minimum 50 MAD';
              return null;
            },
          )
              .animate()
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 16),

          // Commission preview card
          if (commission > 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: willBeBlocked
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  _CommissionRow(
                    label: 'Prix total (client paie)',
                    value: '${priceController.text.trim()} MAD',
                    bold: true,
                  ),
                  const Divider(height: 16),
                  _CommissionRow(
                    label: 'Commission NaqlApp (12%)',
                    value: '- ${commission.toStringAsFixed(0)} MAD',
                    color: AppColors.error,
                  ),
                  const Divider(height: 16),
                  _CommissionRow(
                    label: 'Solde après commission',
                    value: '${walletAfter.toStringAsFixed(0)} MAD',
                    color: willBeBlocked ? AppColors.error : AppColors.success,
                    bold: true,
                  ),
                  if (willBeBlocked) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.error, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Solde insuffisant après commission',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.error),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          NaqlButton(
            label: 'Envoyer mon offre',
            onPressed: willBeBlocked ? null : onSubmit,
            isLoading: isSubmitting,
            icon: Icons.send_rounded,
          ),
        ],
      ),
    );
  }
}

class _CommissionRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  const _CommissionRow({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySecondary),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OfferSentBanner extends StatelessWidget {
  const _OfferSentBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 44),
          const SizedBox(height: 12),
          Text('Offre envoyée !', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            'Le client examinera votre offre et vous contactera s\'il vous choisit.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Retour aux missions'),
          ),
        ],
      ),
    )
        .animate()
        .scale(duration: 500.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 300.ms);
  }
}
