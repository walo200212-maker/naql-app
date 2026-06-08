import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/naql_button.dart';

class JobCompleteScreen extends StatefulWidget {
  final String jobId;
  const JobCompleteScreen({super.key, required this.jobId});

  @override
  State<JobCompleteScreen> createState() => _JobCompleteScreenState();
}

class _JobCompleteScreenState extends State<JobCompleteScreen> {
  double _rating = 5.0;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final provider = context.read<JobProvider>();
    final job = provider.activeJob;
    if (job == null) return;
    await provider.completeJob(
      jobId: widget.jobId,
      driverId: job.matchedDriverId!,
      agreedPrice: job.agreedPrice!,
      rating: _rating,
      review: _reviewController.text.trim(),
    );
    if (!mounted) return;
    context.go(AppRoutes.clientHome);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobProvider>();
    final job = provider.activeJob;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Confirmer la livraison'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 64,
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            Text('Mission terminée !', style: AppTextStyles.display)
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 8),

            Text(
              'Comment évaluez-vous le chauffeur ?',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 32),

            // Rating stars
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              itemCount: 5,
              itemSize: 48,
              glowColor: AppColors.warning,
              itemBuilder: (ctx, idx) =>
                  const Icon(Icons.star_rounded, color: AppColors.warning),
              onRatingUpdate: (r) => setState(() => _rating = r),
            )
                .animate(delay: 400.ms)
                .scale(duration: 400.ms, curve: Curves.elasticOut),

            const SizedBox(height: 32),

            // Review
            TextFormField(
              controller: _reviewController,
              maxLines: 3,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Laissez un commentaire (optionnel)...',
              ),
            )
                .animate(delay: 500.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 16),

            // Price reminder
            if (job?.agreedPrice != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text('À payer au chauffeur',
                        style: AppTextStyles.bodySecondary),
                    const SizedBox(height: 4),
                    Text(
                      '${job!.agreedPrice!.toStringAsFixed(0)} MAD',
                      style: AppTextStyles.price,
                    ),
                    Text('en cash', style: AppTextStyles.caption),
                  ],
                ),
              )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 400.ms),

            const SizedBox(height: 32),

            NaqlButton(
              label: 'Confirmer et noter',
              onPressed: _complete,
              isLoading: provider.isLoading,
              icon: Icons.check_rounded,
            )
                .animate(delay: 700.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
