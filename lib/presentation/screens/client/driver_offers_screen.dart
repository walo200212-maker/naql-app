import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/offer_model.dart';
import '../../../data/models/driver_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../providers/job_provider.dart';

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
        title: Text('${offers.length} offre(s)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: offers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_empty_rounded,
                      size: 72, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('En attente d\'offres', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text('Les chauffeurs à proximité\nvont bientôt répondre',
                      style: AppTextStyles.bodySecondary,
                      textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: offers.length,
              itemBuilder: (_, i) {
                final offer = offers[i];
                return FutureBuilder<DriverModel?>(
                  future: _fetchDriver(offer.driverId),
                  builder: (_, snap) {
                    final driver = snap.data;
                    return _OfferCard(
                      offer: offer,
                      driver: driver,
                      onSelect: () => _selectDriver(offer),
                      onWhatsApp: driver != null
                          ? () => _openWhatsApp(driver.phone)
                          : null,
                    ).animate(delay: (i * 80).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
                  },
                );
              },
            ),
    );
  }
}

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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Truck photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: driver?.truckPhotoUrl.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: driver!.truckPhotoUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            width: 72,
                            height: 72,
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.local_shipping_rounded,
                                color: AppColors.primary),
                          ),
                          errorWidget: (_, _, _) => Container(
                            width: 72,
                            height: 72,
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.local_shipping_rounded,
                                color: AppColors.primary),
                          ),
                        )
                      : Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_shipping_rounded,
                              color: AppColors.primary, size: 36),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver?.name ?? 'Chauffeur',
                          style: AppTextStyles.bodyLarge),
                      const SizedBox(height: 4),
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
                          itemSize: 16,
                        ),
                        Text('${driver!.totalJobs} missions',
                            style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      offer.totalPrice.toStringAsFixed(0),
                      style: AppTextStyles.price,
                    ),
                    Text('MAD', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),

          // Commission info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.textSecondary, size: 14),
                const SizedBox(width: 8),
                Text(
                  'Vous payez ${offer.totalPrice.toStringAsFixed(0)} MAD en cash au chauffeur',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (onWhatsApp != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onWhatsApp,
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text('WhatsApp'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                if (onWhatsApp != null) const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text('Choisir', style: AppTextStyles.button),
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
