import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/models/driver_model.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/naql_button.dart';
import '../../widgets/common/status_badge.dart';

class JobConfirmedScreen extends StatefulWidget {
  final String jobId;
  const JobConfirmedScreen({super.key, required this.jobId});

  @override
  State<JobConfirmedScreen> createState() => _JobConfirmedScreenState();
}

class _JobConfirmedScreenState extends State<JobConfirmedScreen> {
  final _firestore = FirestoreService();
  DriverModel? _driver;

  @override
  void initState() {
    super.initState();
    context.read<JobProvider>().watchJob(widget.jobId);
    _loadDriver();
  }

  Future<void> _loadDriver() async {
    final job = context.read<JobProvider>().activeJob;
    if (job?.matchedDriverId != null) {
      final d = await _firestore.getDriver(job!.matchedDriverId!);
      if (mounted) setState(() => _driver = d);
    }
  }

  Future<void> _openWhatsApp() async {
    if (_driver == null) return;
    final uri = Uri.parse('https://wa.me/${_driver!.phone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _confirmStart() async {
    await context
        .read<JobProvider>()
        .confirmJobStarted(widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    final job = context.watch<JobProvider>().activeJob;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mission confirmée'),
        automaticallyImplyLeading: false,
      ),
      body: job == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Status banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success.withValues(alpha: 0.2),
                          AppColors.surfaceVariant,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 52)
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 12),
                        Text('Chauffeur en route !',
                            style: AppTextStyles.h2),
                        const SizedBox(height: 4),
                        StatusBadge(status: job.status),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  // Driver card
                  if (_driver != null)
                    _DriverInfoCard(driver: _driver!, onWhatsApp: _openWhatsApp)
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 400.ms),

                  const SizedBox(height: 16),

                  // Job summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'Prix convenu',
                          value:
                              '${job.agreedPrice?.toStringAsFixed(0) ?? '-'} MAD',
                          highlight: true,
                        ),
                        const Divider(),
                        _SummaryRow(
                          label: 'Distance',
                          value: '${job.distanceKm.toStringAsFixed(1)} km',
                        ),
                        const Divider(),
                        _SummaryRow(
                          label: 'Paiement',
                          value: 'Cash au chauffeur',
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 32),

                  if (job.status == AppConstants.jobStatusMatched)
                    NaqlButton(
                      label: 'Confirmer le départ',
                      onPressed: _confirmStart,
                      icon: Icons.play_arrow_rounded,
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 400.ms),

                  if (job.status == AppConstants.jobStatusInProgress) ...[
                    // Live driver location map
                    if (job.matchedDriverId != null)
                      _LiveDriverMap(
                        driverId: job.matchedDriverId!,
                        dropoffLat: job.dropoffLocation.lat,
                        dropoffLng: job.dropoffLocation.lng,
                      ).animate(delay: 250.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_rounded,
                              color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Déménagement en cours...',
                              style: AppTextStyles.bodyLarge
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    NaqlButton(
                      label: 'Confirmer la livraison',
                      onPressed: () => context.push(
                          AppRoutes.jobComplete,
                          extra: widget.jobId),
                      icon: Icons.check_rounded,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _DriverInfoCard extends StatelessWidget {
  final DriverModel driver;
  final VoidCallback onWhatsApp;

  const _DriverInfoCard({required this.driver, required this.onWhatsApp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.name, style: AppTextStyles.bodyLarge),
                Text(driver.truckType, style: AppTextStyles.bodySecondary),
                Text('⭐ ${driver.rating.toStringAsFixed(1)}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            onPressed: onWhatsApp,
            icon: const Icon(Icons.chat_rounded, color: AppColors.success),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.success.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySecondary),
          Text(
            value,
            style: highlight
                ? AppTextStyles.h3.copyWith(color: AppColors.primary)
                : AppTextStyles.bodyLarge,
          ),
        ],
      ),
    );
  }
}

// ─── Live driver map ──────────────────────────────────────────────────────────

class _LiveDriverMap extends StatefulWidget {
  final String driverId;
  final double dropoffLat;
  final double dropoffLng;

  const _LiveDriverMap({
    required this.driverId,
    required this.dropoffLat,
    required this.dropoffLng,
  });

  @override
  State<_LiveDriverMap> createState() => _LiveDriverMapState();
}

class _LiveDriverMapState extends State<_LiveDriverMap> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final dropoff = LatLng(widget.dropoffLat, widget.dropoffLng);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('drivers')
              .doc(widget.driverId)
              .snapshots(),
          builder: (_, snap) {
            LatLng? driverPos;
            if (snap.hasData && snap.data!.exists) {
              final data = snap.data!.data() as Map<String, dynamic>?;
              final geo = data?['location'] as GeoPoint?;
              if (geo != null) {
                driverPos = LatLng(geo.latitude, geo.longitude);
                _mapController
                    ?.animateCamera(CameraUpdate.newLatLng(driverPos));
              }
            }

            return GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: driverPos ?? dropoff, zoom: 14),
              onMapCreated: (c) => _mapController = c,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                if (driverPos != null)
                  Marker(
                    markerId: const MarkerId('driver'),
                    position: driverPos,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange),
                    infoWindow: const InfoWindow(title: 'Chauffeur en route'),
                  ),
                Marker(
                  markerId: const MarkerId('dropoff'),
                  position: dropoff,
                  infoWindow: const InfoWindow(title: 'Destination'),
                ),
              },
            );
          },
        ),
      ),
    );
  }
}
