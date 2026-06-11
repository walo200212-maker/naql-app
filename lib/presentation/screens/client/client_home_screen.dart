import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Marker;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/wasl_button.dart';
import '../../widgets/common/wasl_bottom_nav.dart';
import 'home_content_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  GoogleMapController? _mapController;
  final MapController _webMapController = MapController();
  LatLng _center = const LatLng(33.5731, -7.5898); // Casablanca default
  int _selectedTab = 0;

  // `myLocationEnabled` must stay false until permission is confirmed —
  // enabling it before the OS grants ACCESS_FINE/COARSE_LOCATION throws a
  // PlatformException on Android that prevents the GoogleMap view from
  // rendering at all.
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    final auth = context.read<AuthProvider>();
    if (auth.uid != null) {
      context.read<JobProvider>().watchClientJobs(auth.uid!);
    }
  }

  Future<void> _initLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      if (mounted) setState(() => _locationGranted = true);
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _center = LatLng(pos.latitude, pos.longitude));
      _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
    } catch (_) {}
  }

  void _goToMyLocation() {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
    try {
      _webMapController.move(ll.LatLng(_center.latitude, _center.longitude), 15);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedTab,
            children: [
              const HomeContentScreen(),
              const _HistoryTab(),
              _HomeTab(
                center: _center,
                locationEnabled: _locationGranted,
                onMapCreated: (c) => _mapController = c,
                onMyLocation: _goToMyLocation,
                webMapController: _webMapController,
              ),
              const _ProfileTab(),
            ],
          ),

          // Floating bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedTab == 2) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: WaslButton(
                      label: 'انشر طلب جديد',
                      onPressed: () => context.push(AppRoutes.postJob),
                      icon: Icons.add_rounded,
                    ),
                  )
                      .animate()
                      .slideY(
                          begin: 0.4,
                          end: 0,
                          duration: 450.ms,
                          delay: 300.ms,
                          curve: Curves.easeOutCubic)
                      .fadeIn(duration: 350.ms, delay: 300.ms),
                ],
                WaslBottomNav(
                  currentIndex: _selectedTab,
                  onTap: (i) => setState(() => _selectedTab = i),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final LatLng center;
  final bool locationEnabled;
  final void Function(GoogleMapController) onMapCreated;
  final VoidCallback onMyLocation;
  final MapController webMapController;

  const _HomeTab({
    required this.center,
    required this.locationEnabled,
    required this.onMapCreated,
    required this.onMyLocation,
    required this.webMapController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // OpenStreetMap on web (no billing needed), Google Maps on mobile
        if (kIsWeb)
          _WebMap(center: center, controller: webMapController)
        else
          GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 13),
            onMapCreated: onMapCreated,
            myLocationEnabled: locationEnabled,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapType: MapType.normal,
            style: _darkMapStyle,
          ),

        // Frosted glass top bar
        SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.surfaceBorder.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Consumer<AuthProvider>(
                    builder: (ctx, auth, child) => Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlow,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('أهلاً بك 👋',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textHint)),
                              Text(
                                auth.user?.name ?? 'عميل',
                                style: AppTextStyles.bodyLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _TopBarButton(
                          icon: Icons.my_location_rounded,
                          onTap: onMyLocation,
                        ),
                        const SizedBox(width: 8),
                        _TopBarButton(
                          icon: Icons.notifications_outlined,
                          onTap: () => ctx.push(AppRoutes.notifications),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
              .animate()
              .slideY(begin: -0.3, end: 0, duration: 500.ms)
              .fadeIn(duration: 400.ms),
        ),
      ],
    );
  }
}

class _WebMap extends StatelessWidget {
  final LatLng center;
  final MapController controller;

  const _WebMap({required this.center, required this.controller});

  @override
  Widget build(BuildContext context) {
    final point = ll.LatLng(center.latitude, center.longitude);
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: point,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.wasl.naql_app',
          retinaMode: true,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
            TextSourceAttribution('© CARTO'),
          ],
        ),
      ],
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }
}

// ─── History Tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>().clientJobs;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'طلباتي',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
      ),
      body: jobs.isEmpty
          ? _EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'لا يوجد طلبات بعد',
              subtitle: 'انشر طلبك الأول للانتقال',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: jobs.length,
              itemBuilder: (ctx, i) {
                final job = jobs[i];
                return GestureDetector(
                  onTap: () =>
                      ctx.push(AppRoutes.jobPosted, extra: job.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(job.city,
                                style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700)),
                            StatusBadge(status: job.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _LocationRow(
                          icon: Icons.circle,
                          color: AppColors.success,
                          text: job.pickupLocation.address,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Column(
                            children: List.generate(
                                2,
                                (_) => Container(
                                      width: 1.5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 1),
                                      color: AppColors.surfaceBorder,
                                    )),
                          ),
                        ),
                        _LocationRow(
                          icon: Icons.location_on_rounded,
                          color: AppColors.primary,
                          text: job.dropoffLocation.address,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.straighten_rounded,
                                size: 14, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              '${job.distanceKm.toStringAsFixed(1)} كم',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time_rounded,
                                size: 14, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(job.createdAt),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate(delay: Duration(milliseconds: i * 60))
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.06, end: 0),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loggedIn = auth.uid != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'حسابي',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Avatar + name hero
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGlow,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.primary, size: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  loggedIn ? (auth.user?.name ?? 'عميل') : 'زائر',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 4),
                Text(
                  loggedIn
                      ? (auth.user?.phone ?? '')
                      : 'سجل الدخول للوصول إلى حسابك وطلباتك',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                if (!loggedIn) ...[
                  const SizedBox(height: 16),
                  WaslButton(
                    label: 'تسجيل الدخول',
                    icon: Icons.login_rounded,
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                ],
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, end: 0),

          const SizedBox(height: 20),

          _MenuSection(
            title: 'الإعدادات',
            items: [
              _MenuItemData(
                icon: Icons.settings_rounded,
                label: 'الإعدادات',
                onTap: () => context.push(AppRoutes.settings),
              ),
              _MenuItemData(
                icon: Icons.help_outline_rounded,
                label: 'المساعدة والدعم',
                onTap: () => context.push(AppRoutes.support),
              ),
            ],
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

          if (loggedIn) ...[
            const SizedBox(height: 12),
            _MenuSection(
              title: 'الحساب',
              items: [
                _MenuItemData(
                  icon: Icons.logout_rounded,
                  label: 'تسجيل الخروج',
                  color: AppColors.error,
                  onTap: () async {
                    await auth.signOut();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                ),
              ],
            ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
          ],
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _LocationRow(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

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
              color: AppColors.surfaceHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: AppColors.textHint),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuItemData(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItemData> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(title, style: AppTextStyles.label),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final item = e.value;
              final isLast = e.key == items.length - 1;
              final c = item.color ?? AppColors.textPrimary;
              return Column(
                children: [
                  ListTile(
                    onTap: item.onTap,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (item.color ?? AppColors.primary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: c, size: 18),
                    ),
                    title: Text(
                      item.label,
                      style: AppTextStyles.body.copyWith(color: c),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: AppColors.textHint),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 2),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Divider(
                          color: AppColors.surfaceBorder, height: 1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Dark map style ───────────────────────────────────────────────────────────

const _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#141414"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6b6b6b"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#181818"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#252525"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#303030"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#383838"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#F97316","lightness":-70}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a0a0a"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#1c1c1c"}]},
  {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]}
]
''';
