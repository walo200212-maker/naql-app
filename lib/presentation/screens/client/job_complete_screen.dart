import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/wasl_button.dart';

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
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('تأكيد الاستلام', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success hero
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.2),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
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

            const SizedBox(height: 28),

            Text('تم التوصيل! 🎉', style: AppTextStyles.display)
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 8),

            Text(
              'كيف تقيّم السائق؟',
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
              itemSize: 50,
              glowColor: AppColors.warning,
              itemBuilder: (ctx, idx) =>
                  const Icon(Icons.star_rounded, color: AppColors.warning),
              onRatingUpdate: (r) => setState(() => _rating = r),
            )
                .animate(delay: 400.ms)
                .scale(duration: 400.ms, curve: Curves.elasticOut),

            const SizedBox(height: 10),

            // Rating label
            Text(
              _ratingLabel(_rating),
              style: AppTextStyles.body.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            )
                .animate(delay: 450.ms)
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 28),

            // Review field
            TextFormField(
              controller: _reviewController,
              maxLines: 3,
              style: AppTextStyles.body,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'اترك تعليقاً (اختياري)...',
              ),
            )
                .animate(delay: 500.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // Price reminder
            if (job?.agreedPrice != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Text('ادفع للسائق',
                        style: AppTextStyles.bodySecondary),
                    const SizedBox(height: 6),
                    Text(
                      job!.agreedPrice!.toStringAsFixed(0),
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Text('درهم نقداً', style: AppTextStyles.bodySecondary),
                  ],
                ),
              )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 400.ms),

            const SizedBox(height: 32),

            WaslButton(
              label: 'تأكيد وتقييم',
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

  String _ratingLabel(double r) {
    if (r >= 5) return 'ممتاز!';
    if (r >= 4) return 'جيد جداً';
    if (r >= 3) return 'جيد';
    if (r >= 2) return 'مقبول';
    return 'سيئ';
  }
}
