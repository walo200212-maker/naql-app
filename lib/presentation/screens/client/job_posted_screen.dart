import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/wasl_button.dart';
import '../../widgets/common/wasl_shimmer.dart';

class JobPostedScreen extends StatefulWidget {
  final String jobId;
  const JobPostedScreen({super.key, required this.jobId});

  @override
  State<JobPostedScreen> createState() => _JobPostedScreenState();
}

class _JobPostedScreenState extends State<JobPostedScreen> {
  @override
  void initState() {
    super.initState();
    context.read<JobProvider>().watchJob(widget.jobId);
    context.read<JobProvider>().watchJobOffers(widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobProvider>();
    final job = provider.activeJob;
    final offers = provider.jobOffers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'طلبك',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.clientHome),
            child: Text(
              'الرئيسية',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: job == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status hero card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.18),
                          AppColors.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.local_shipping_rounded,
                              color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تم نشر طلبك! 🎉',
                                style: AppTextStyles.h3,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                offers.isEmpty
                                    ? 'في انتظار عروض السائقين...'
                                    : 'وصل ${offers.length} عرض',
                                style: AppTextStyles.bodySecondary.copyWith(
                                  color: offers.isNotEmpty
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (offers.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.success
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '${offers.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.1, end: 0),

                  const SizedBox(height: 20),

                  // Route card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Column(
                      children: [
                        _RoutePoint(
                          icon: Icons.circle,
                          color: AppColors.success,
                          label: 'الانطلاق',
                          address: job.pickupLocation.address,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Row(
                            children: List.generate(
                              3,
                              (_) => Container(
                                width: 1.5,
                                height: 5,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 1),
                                color: AppColors.surfaceBorder,
                              ),
                            ),
                          ),
                        ),
                        _RoutePoint(
                          icon: Icons.location_on_rounded,
                          color: AppColors.primary,
                          label: 'الوصول',
                          address: job.dropoffLocation.address,
                        ),
                        const SizedBox(height: 12),
                        Divider(color: AppColors.surfaceBorder, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.straighten_rounded,
                                color: AppColors.textHint, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '${job.distanceKm.toStringAsFixed(1)} كم',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  // Offers section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('عروض السائقين', style: AppTextStyles.h3),
                      if (offers.isNotEmpty)
                        GestureDetector(
                          onTap: () => context.push(
                              AppRoutes.driverOffers,
                              extra: widget.jobId),
                          child: Text(
                            'عرض الكل',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (offers.isEmpty) ...[
                    const WaslShimmerList(count: 2),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'السائقون القريبون يرون إعلانك الآن...',
                        style: AppTextStyles.bodySecondary,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else
                    ...offers.take(3).toList().asMap().entries.map((e) =>
                        _OfferPreviewCard(
                          offer: e.value,
                          jobId: widget.jobId,
                          distanceKm: job.distanceKm,
                        )
                            .animate(
                                delay: Duration(milliseconds: e.key * 80))
                            .fadeIn(duration: 350.ms)
                            .slideY(begin: 0.06, end: 0)),
                ],
              ),
            ),
    );
  }
}

// ─── Route point ──────────────────────────────────────────────────────────────

class _RoutePoint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _RoutePoint({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(
                address,
                style: AppTextStyles.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Offer preview card ───────────────────────────────────────────────────────

class _OfferPreviewCard extends StatelessWidget {
  final dynamic offer;
  final String jobId;
  final double distanceKm;

  const _OfferPreviewCard({
    required this.offer,
    required this.jobId,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryGlow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سائق 🚛', style: AppTextStyles.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  '${offer.totalPrice.toStringAsFixed(0)} درهم',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          WaslButton(
            label: 'اختر',
            height: 40,
            onPressed: () => context.push(AppRoutes.driverOffers,
                extra: jobId),
          ),
        ],
      ),
    );
  }
}
