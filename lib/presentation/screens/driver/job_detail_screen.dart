import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/offer_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/wasl_button.dart';
import '../../widgets/common/wasl_toast.dart';

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

  double get _enteredPrice =>
      double.tryParse(_priceController.text.trim()) ?? 0;

  double get _commission => _enteredPrice * AppConstants.commissionRate;

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_job == null) return;
    final auth = context.read<AuthProvider>();
    if (auth.uid == null) return;
    final driver = auth.driver;
    if (driver == null) return;

    if (!driver.canAcceptJobs) {
      WaslToast.show(context, 'الرصيد غير كافٍ لتقديم عرض',
          type: ToastType.error);
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
        WaslToast.show(context, e.toString(), type: ToastType.error);
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
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text('تفاصيل المهمة',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ),
        body: Center(
          child: Text(_error ?? 'المهمة غير موجودة',
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
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'تفاصيل المهمة',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(child: StatusBadge(status: job.status)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.straighten_rounded,
                    label: 'المسافة',
                    value: '${job.distanceKm.toStringAsFixed(1)} كم',
                    valueColor: AppColors.primary,
                  ),
                  Divider(color: AppColors.surfaceBorder, height: 20),
                  _DetailRow(
                    icon: Icons.location_city_rounded,
                    label: 'المدينة',
                    value: job.city,
                  ),
                  if (job.isIntercity) ...[
                    Divider(color: AppColors.surfaceBorder, height: 20),
                    _DetailRow(
                      icon: Icons.swap_horiz_rounded,
                      label: 'النوع',
                      value: 'بين المدن',
                      valueColor: AppColors.info,
                    ),
                  ],
                  if (job.itemsDescription.isNotEmpty) ...[
                    Divider(color: AppColors.surfaceBorder, height: 20),
                    _DetailRow(
                      icon: Icons.inventory_2_rounded,
                      label: 'الوصف',
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
              const SizedBox(height: 20),
              Text('صور البضائع', style: AppTextStyles.label),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: job.itemsPhotos.length,
                  itemBuilder: (ctx, i) => Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      image: DecorationImage(
                        image: NetworkImage(job.itemsPhotos[i]),
                        fit: BoxFit.cover,
                      ),
                      color: AppColors.surfaceHigh,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Offer section
            if (job.status == AppConstants.jobStatusOpen) ...[
              if (_offerSubmitted)
                const _OfferSentBanner()
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
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded,
                        color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'هذه المهمة لم تعد متاحة للعروض.',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Route card ───────────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final JobModel job;
  const _RouteCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المسار', style: AppTextStyles.label),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.circle,
                      color: AppColors.success, size: 12),
                  Container(
                    width: 2,
                    height: 40,
                    color: AppColors.surfaceBorder,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 16),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الانطلاق', style: AppTextStyles.caption),
                    Text(
                      job.pickupLocation.address,
                      style: AppTextStyles.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 22),
                    Text('الوصول', style: AppTextStyles.caption),
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

// ─── Detail row ───────────────────────────────────────────────────────────────

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
        Icon(icon, color: AppColors.primary, size: 17),
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

// ─── Offer form ───────────────────────────────────────────────────────────────

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
          Text('قدم عرضك', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            'سيرى العميل سعرك ويختار أفضل سائق.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 20),

          // Price input
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGlow,
                  blurRadius: 16,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'درهم',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHint,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (_) => onChanged(),
                    validator: (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      if (n == null || n <= 0) return 'أدخل سعراً صالحاً';
                      if (n < 50) return 'الحد الأدنى 50 درهم';
                      return null;
                    },
                  ),
                ),
                Text(
                  'الإجمالي',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 16),

          // Commission breakdown
          if (commission > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: willBeBlocked
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.surfaceBorder,
                ),
              ),
              child: Column(
                children: [
                  _CommRow(
                    label: 'السعر الإجمالي (يدفعه العميل)',
                    value: '${priceController.text.trim()} درهم',
                    bold: true,
                  ),
                  Divider(color: AppColors.surfaceBorder, height: 16),
                  _CommRow(
                    label: 'عمولة وصل (12%)',
                    value: '- ${commission.toStringAsFixed(0)} درهم',
                    color: AppColors.error,
                  ),
                  Divider(color: AppColors.surfaceBorder, height: 16),
                  _CommRow(
                    label: 'الرصيد بعد العمولة',
                    value: '${walletAfter.toStringAsFixed(0)} درهم',
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
                          'الرصيد غير كافٍ بعد العمولة',
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

          WaslButton(
            label: 'إرسال عرضي',
            onPressed: willBeBlocked ? null : onSubmit,
            isLoading: isSubmitting,
            icon: Icons.send_rounded,
          ),
        ],
      ),
    );
  }
}

class _CommRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  const _CommRow({
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

// ─── Offer sent banner ────────────────────────────────────────────────────────

class _OfferSentBanner extends StatelessWidget {
  const _OfferSentBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 40),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text('تم إرسال عرضك! 🎉', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'سيراجع العميل عرضك وسيتصل بك إذا اختارك.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          WaslButton(
            label: 'العودة للطلبات',
            variant: WaslButtonVariant.outline,
            onPressed: () => context.pop(),
            icon: Icons.arrow_back_rounded,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }
}
