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
import '../../widgets/common/wasl_button.dart';
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
    await context.read<JobProvider>().confirmJobStarted(widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    final job = context.watch<JobProvider>().activeJob;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: job == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                // App bar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.background,
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  title: Text('تتبع الطلب', style: AppTextStyles.h3),
                  centerTitle: true,
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Status hero
                      _StatusHero(job: job)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.08, end: 0),

                      const SizedBox(height: 20),

                      // Driver card
                      if (_driver != null)
                        _DriverCard(
                          driver: _driver!,
                          onWhatsApp: _openWhatsApp,
                        )
                            .animate(delay: 100.ms)
                            .fadeIn(duration: 400.ms),

                      const SizedBox(height: 16),

                      // Job summary
                      _JobSummaryCard(job: job)
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 400.ms),

                      const SizedBox(height: 24),

                      // Live map (in-progress)
                      if (job.status == AppConstants.jobStatusInProgress &&
                          job.matchedDriverId != null) ...[
                        _LiveDriverMap(
                          driverId: job.matchedDriverId!,
                          dropoffLat: job.dropoffLocation.lat,
                          dropoffLng: job.dropoffLocation.lng,
                        )
                            .animate(delay: 250.ms)
                            .fadeIn(duration: 400.ms),
                        const SizedBox(height: 16),
                        _InProgressBanner()
                            .animate(delay: 300.ms)
                            .fadeIn(duration: 400.ms),
                        const SizedBox(height: 16),
                        WaslButton(
                          label: 'تأكيد الاستلام',
                          onPressed: () => context.push(
                              AppRoutes.jobComplete,
                              extra: widget.jobId),
                          icon: Icons.check_rounded,
                        )
                            .animate(delay: 350.ms)
                            .fadeIn(duration: 400.ms),
                      ],

                      // Confirm start (matched)
                      if (job.status == AppConstants.jobStatusMatched)
                        WaslButton(
                          label: 'تأكيد انطلاق السائق',
                          onPressed: _confirmStart,
                          icon: Icons.play_arrow_rounded,
                        )
                            .animate(delay: 300.ms)
                            .fadeIn(duration: 400.ms),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Status hero ──────────────────────────────────────────────────────────────

class _StatusHero extends StatelessWidget {
  final dynamic job;
  const _StatusHero({required this.job});

  @override
  Widget build(BuildContext context) {
    final isInProgress = job.status == AppConstants.jobStatusInProgress;
    final color = isInProgress ? AppColors.primary : AppColors.success;
    final icon = isInProgress
        ? Icons.local_shipping_rounded
        : Icons.check_circle_rounded;
    final title = isInProgress ? 'النقل جارٍ الآن' : 'السائق في الطريق!';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 38),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                  begin: 1, end: 1.06, duration: 1200.ms, curve: Curves.easeInOut),
          const SizedBox(height: 14),
          Text(title, style: AppTextStyles.h2),
          const SizedBox(height: 6),
          StatusBadge(status: job.status),
        ],
      ),
    );
  }
}

// ─── Driver card ──────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final DriverModel driver;
  final VoidCallback onWhatsApp;
  const _DriverCard({required this.driver, required this.onWhatsApp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.name, style: AppTextStyles.bodyLarge),
                const SizedBox(height: 2),
                Text(driver.truckType, style: AppTextStyles.bodySecondary),
                const SizedBox(height: 2),
                Text('⭐ ${driver.rating.toStringAsFixed(1)}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          // WhatsApp button
          GestureDetector(
            onTap: onWhatsApp,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_rounded,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text('واتساب',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.success,
                              fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Job summary ──────────────────────────────────────────────────────────────

class _JobSummaryCard extends StatelessWidget {
  final dynamic job;
  const _JobSummaryCard({required this.job});

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
        children: [
          _Row(
            label: 'السعر المتفق عليه',
            value: '${job.agreedPrice?.toStringAsFixed(0) ?? '-'} درهم',
            highlight: true,
          ),
          Divider(color: AppColors.surfaceBorder, height: 20),
          _Row(
            label: 'المسافة',
            value: '${job.distanceKm.toStringAsFixed(1)} كم',
          ),
          Divider(color: AppColors.surfaceBorder, height: 20),
          _Row(
            label: 'طريقة الدفع',
            value: 'نقداً للسائق',
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _Row(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

// ─── In-progress banner ───────────────────────────────────────────────────────

class _InProgressBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'النقل جارٍ... سيتم إشعارك عند الوصول',
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
            ),
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
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 220,
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
                    infoWindow: const InfoWindow(title: 'السائق في الطريق'),
                  ),
                Marker(
                  markerId: const MarkerId('dropoff'),
                  position: dropoff,
                  infoWindow: const InfoWindow(title: 'الوجهة'),
                ),
              },
            );
          },
        ),
      ),
    );
  }
}
