import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/naql_button.dart';
import '../../widgets/common/skeleton_loader.dart';

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
        title: const Text('Votre demande'),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.clientHome),
            child: const Text('Retour'),
          ),
        ],
      ),
      body: job == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.surfaceVariant,
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
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.local_shipping_rounded,
                              color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Demande publiée !',
                                  style: AppTextStyles.h3),
                              const SizedBox(height: 4),
                              Text(
                                offers.isEmpty
                                    ? 'En attente d\'offres de chauffeurs...'
                                    : '${offers.length} offre(s) reçue(s)',
                                style: AppTextStyles.bodySecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.1, end: 0),

                  const SizedBox(height: 24),

                  // Route info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _RoutePoint(
                          icon: Icons.circle_rounded,
                          color: AppColors.success,
                          label: 'Départ',
                          address: job.pickupLocation.address,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Container(
                              width: 1,
                              height: 20,
                              color: AppColors.border),
                        ),
                        _RoutePoint(
                          icon: Icons.location_on_rounded,
                          color: AppColors.primary,
                          label: 'Arrivée',
                          address: job.dropoffLocation.address,
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.straighten_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text('${job.distanceKm.toStringAsFixed(1)} km',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Offers section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Offres de chauffeurs', style: AppTextStyles.h3),
                      if (offers.isNotEmpty)
                        TextButton(
                          onPressed: () => context.push(
                              AppRoutes.driverOffers,
                              extra: widget.jobId),
                          child: const Text('Voir tout'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (offers.isEmpty) ...[
                    const DriverCardSkeleton(),
                    const DriverCardSkeleton(),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Les chauffeurs à proximité voient votre annonce...',
                        style: AppTextStyles.bodySecondary,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else
                    ...offers.take(3).map((offer) => _OfferPreviewCard(
                          offer: offer,
                          jobId: widget.jobId,
                          distanceKm: job.distanceKm,
                        )),
                ],
              ),
            ),
    );
  }
}

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
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(address,
                  style: AppTextStyles.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chauffeur', style: AppTextStyles.bodyLarge),
                Text(
                  '${offer.totalPrice.toStringAsFixed(0)} MAD',
                  style:
                      AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          NaqlButton(
            label: 'Choisir',
            height: 40,
            onPressed: () => context.push(AppRoutes.driverOffers,
                extra: jobId),
          ),
        ],
      ),
    );
  }
}
