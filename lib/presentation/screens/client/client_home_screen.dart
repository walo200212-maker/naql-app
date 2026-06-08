import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/status_badge.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(33.5731, -7.5898); // Casablanca default
  int _selectedTab = 0;

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
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _center = LatLng(pos.latitude, pos.longitude));
      _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _HomeTab(center: _center, onMapCreated: (c) => _mapController = c),
          const _HistoryTab(),
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.postJob),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Publier', style: AppTextStyles.button),
            )
              .animate()
              .scale(delay: 400.ms, duration: 400.ms, curve: Curves.elasticOut)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ─── Home Tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final LatLng center;
  final void Function(GoogleMapController) onMapCreated;

  const _HomeTab({required this.center, required this.onMapCreated});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-screen map
        GoogleMap(
          initialCameraPosition: CameraPosition(target: center, zoom: 13),
          onMapCreated: onMapCreated,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          mapType: MapType.normal,
          style: _darkMapStyle,
        ),

        // Top greeting
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20),
                ],
              ),
              child: Consumer<AuthProvider>(
                builder: (_, auth, _) => Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bonjour 👋', style: AppTextStyles.caption),
                          Text(auth.user?.name ?? 'Client',
                              style: AppTextStyles.bodyLarge),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: AppColors.textPrimary),
                      onPressed: () =>
                          context.push(AppRoutes.notifications),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .slideY(begin: -0.3, end: 0, duration: 500.ms)
                .fadeIn(duration: 400.ms),
          ),
        ),

        // Bottom hint
        Positioned(
          bottom: 100,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Appuyez sur + pour publier votre demande de déménagement',
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
              ],
            ),
          )
              .animate(delay: 600.ms)
              .slideY(begin: 0.3, end: 0, duration: 400.ms)
              .fadeIn(duration: 400.ms),
        ),
      ],
    );
  }
}

// ─── History Tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>().clientJobs;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes déménagements')),
      body: jobs.isEmpty
          ? _EmptyState(
              icon: Icons.history_rounded,
              title: 'Aucun déménagement',
              subtitle: 'Publiez votre première demande !',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (_, i) {
                final job = jobs[i];
                return GestureDetector(
                  onTap: () => context.push(AppRoutes.jobPosted,
                      extra: job.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(job.city, style: AppTextStyles.bodyLarge),
                            StatusBadge(status: job.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _LocationRow(
                            icon: Icons.circle_rounded,
                            color: AppColors.success,
                            text: job.pickupLocation.address),
                        const SizedBox(height: 4),
                        _LocationRow(
                            icon: Icons.location_on_rounded,
                            color: AppColors.primary,
                            text: job.dropoffLocation.address),
                        const SizedBox(height: 8),
                        Text(
                          '${job.distanceKm.toStringAsFixed(1)} km',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.primary, size: 44),
                ),
                const SizedBox(height: 12),
                Text(auth.user?.name ?? '', style: AppTextStyles.h2),
                Text(auth.user?.phone ?? '',
                    style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _MenuItem(
              icon: Icons.settings_rounded,
              label: 'Paramètres',
              onTap: () => context.push(AppRoutes.settings)),
          _MenuItem(
              icon: Icons.help_outline_rounded,
              label: 'Aide & Support',
              onTap: () => context.push(AppRoutes.support)),
          _MenuItem(
              icon: Icons.logout_rounded,
              label: 'Déconnexion',
              color: AppColors.error,
              onTap: () async {
                await auth.signOut();
                if (context.mounted) context.go(AppRoutes.login);
              }),
        ],
      ),
    );
  }
}

// ─── Shared widgets ────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: current,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded), label: 'Accueil'),
        BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded), label: 'Historique'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded), label: 'Profil'),
      ],
    );
  }
}

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
          child: Text(text,
              style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis),
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
          Icon(icon, size: 72, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(subtitle,
              style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: c),
      title: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: c)),
      trailing:
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
    );
  }
}

// ─── Dark map style ────────────────────────────────────────────────────────────

const _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1a1a1a"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#212121"}]}
]
''';
