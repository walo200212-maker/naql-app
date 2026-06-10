import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/offer_model.dart';
import '../../../data/models/driver_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/wasl_button.dart';
import '../../widgets/common/wasl_shimmer.dart';

class DriverOffersScreen extends StatefulWidget {
  final String jobId;
  const DriverOffersScreen({super.key, required this.jobId});

  @override
  State<DriverOffersScreen> createState() => _DriverOffersScreenState();
}

class _DriverOffersScreenState extends State<DriverOffersScreen> {
  final _firestoreService = FirestoreService();
  final Map<String, DriverModel> _driversCache = {};

  @override
  void initState() {
    super.initState();
    context.read<JobProvider>().watchJobOffers(widget.jobId);
  }

  Future<DriverModel?> _fetchDriver(String driverId) async {
    if (_driversCache.containsKey(driverId)) return _driversCache[driverId];
    final driver = await _firestoreService.getDriver(driverId);
    if (driver != null) _driversCache[driverId] = driver;
    return driver;
  }

  Future<void> _selectDriver(OfferModel offer) async {
    final provider = context.read<JobProvider>();
    await provider.selectDriver(
      jobId: widget.jobId,
      driverId: offer.driverId,
      offerId: offer.id,
      agreedPrice: offer.totalPrice,
    );
    if (!mounted) return;
    context.pushReplacement(AppRoutes.jobConfirmed, extra: widget.jobId);
  }

  Future<void> _openWhatsApp(String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final offers = context.watch<JobProvider>().jobOffers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          offers.isEmpty ? 'عروض السائقين' : '${offers.length} عرض',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
      ),
      body: offers.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: offers.length,
              itemBuilder: (_, i) {
                final offer = offers[i];
                return FutureBuilder<DriverModel?>(
                  future: _fetchDriver(offer.driverId),
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: WaslShimmerList(count: 1),
                      );
                    }
                    return _OfferCard(
                      offer: offer,
                      driver: snap.data,
                      onSelect: () => _selectDriver(offer),
                      onWhatsApp: snap.data != null
                          ? () => _openWhatsApp(snap.data!.phone)
                          : null,
                    )
                        .animate(delay: Duration(milliseconds: i * 80))
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.08, end: 0);
                  },
                );
              },
            ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Icon(Icons.hourglass_empty_rounded,
                size: 44, color: AppColors.textHint),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.06, duration: 1400.ms),
          const SizedBox(height: 20),
          Text('في انتظار العروض', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'السائقون القريبون منك\nسيردون قريباً',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Offer card ───────────────────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  final DriverModel? driver;
  final VoidCallback onSelect;
  final VoidCallback? onWhatsApp;

  const _OfferCard({
    required this.offer,
    required this.driver,
    required this.onSelect,
    this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Truck photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: driver?.truckPhotoUrl.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: driver!.truckPhotoUrl,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => _TruckPlaceholder(),
                          errorWidget: (_, _, _) => _TruckPlaceholder(),
                        )
                      : _TruckPlaceholder(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver?.name ?? 'سائق',
                          style: AppTextStyles.bodyLarge),
                      const SizedBox(height: 3),
                      if (driver != null) ...[
                        Text(driver!.truckType,
                            style: AppTextStyles.bodySecondary),
                        const SizedBox(height: 4),
                        RatingBarIndicator(
                          rating: driver!.rating,
                          itemBuilder: (_, _) => const Icon(
                              Icons.star_rounded,
                              color: AppColors.warning),
                          itemCount: 5,
                          itemSize: 15,
                        ),
                        const SizedBox(height: 2),
                        Text('${driver!.totalJobs} رحلة',
                            style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      offer.totalPrice.toStringAsFixed(0),
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Text('درهم', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),

          // Payment info strip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined,
                    color: AppColors.textHint, size: 14),
                const SizedBox(width: 8),
                Text(
                  'تدفع ${offer.totalPrice.toStringAsFixed(0)} درهم نقداً للسائق',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                if (onWhatsApp != null) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: onWhatsApp,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_rounded,
                                color: AppColors.success, size: 17),
                            const SizedBox(width: 6),
                            Text('واتساب',
                                style: AppTextStyles.body.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: WaslButton(
                    label: 'اختر هذا السائق',
                    height: 48,
                    onPressed: onSelect,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TruckPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(Icons.local_shipping_rounded,
          color: AppColors.primary, size: 36),
    );
  }
}
