import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/skeleton_loader.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.driver != null) {
      context.read<JobProvider>().watchOpenJobs(auth.driver!.city);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _tab,
        children: const [
          _JobFeedTab(),
          _WalletShortcutTab(),
          _DriverProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.work_outline_rounded), label: 'Missions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Portefeuille'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}

// ─── Job Feed ─────────────────────────────────────────────────────────────────

class _JobFeedTab extends StatelessWidget {
  const _JobFeedTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<JobProvider>();
    final driver = auth.driver;

    // Blocked state
    if (driver != null && !driver.canAcceptJobs) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Missions disponibles')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_rounded,
                      color: AppColors.error, size: 52),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                Text(
                  driver.walletBalance < AppConstants.minWalletBalance
                      ? S.lowBalanceTitle
                      : 'Compte en attente',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  driver.walletBalance < AppConstants.minWalletBalance
                      ? S.lowBalanceMsg
                      : 'Votre compte est en cours de validation par l\'admin.',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (driver.walletBalance < AppConstants.minWalletBalance)
                  ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.topUp),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Recharger maintenant'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Missions disponibles'),
        actions: [
          // Wallet balance chip
          if (driver != null)
            GestureDetector(
              onTap: () => context.push(AppRoutes.wallet),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: driver.walletBalance < AppConstants.lowWalletWarning
                      ? AppColors.error.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 14,
                      color:
                          driver.walletBalance < AppConstants.lowWalletWarning
                              ? AppColors.error
                              : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      CurrencyFormatter.formatCompact(driver.walletBalance),
                      style: AppTextStyles.caption.copyWith(
                        color:
                            driver.walletBalance < AppConstants.lowWalletWarning
                                ? AppColors.error
                                : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Online / Offline toggle ──────────────────────────────────────
          _OnlineToggle(
            isOnline: driver?.isOnline ?? false,
            onToggle: (val) => context.read<AuthProvider>().toggleOnline(val),
          ),
          // ── Job list ─────────────────────────────────────────────────────
          Expanded(
            child: provider.openJobs.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                JobCardSkeleton(),
                JobCardSkeleton(),
                JobCardSkeleton(),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.openJobs.length,
              itemBuilder: (_, i) {
                final job = provider.openJobs[i];
                return _JobCard(job: job, driver: driver)
                    .animate(delay: (i * 60).ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.05, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Online / Offline toggle card ─────────────────────────────────────────────

class _OnlineToggle extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onToggle;

  const _OnlineToggle({required this.isOnline, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOnline
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOnline
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.textHint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'En ligne' : 'Hors ligne',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isOnline ? AppColors.success : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isOnline
                      ? 'Visible aux clients · Localisation active'
                      : 'Activez pour voir les missions disponibles',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: isOnline,
            onChanged: onToggle,
            activeThumbColor: AppColors.success,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  final dynamic driver;

  const _JobCard({required this.job, this.driver});

  @override
  Widget build(BuildContext context) {
    final commission = (job.distanceKm *
            (driver?.pricePerKm ?? 8) *
            AppConstants.commissionRate);
    final walletAfter = (driver?.walletBalance ?? 0) - commission;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.jobDetail, extra: job.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(job.city,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                    if (job.isIntercity) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Intercity',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${job.distanceKm.toStringAsFixed(1)} km',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route
            Row(
              children: [
                const Icon(Icons.circle_rounded,
                    color: AppColors.success, size: 10),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(job.pickupLocation.address,
                      style: AppTextStyles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
              child: Container(
                  width: 2, height: 14, color: AppColors.border),
            ),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: AppColors.primary, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(job.dropoffLocation.address,
                      style: AppTextStyles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Commission preview
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: AppColors.textSecondary, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Commission estimée: ${commission.toStringAsFixed(0)} MAD · Solde après: ${walletAfter.toStringAsFixed(0)} MAD',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wallet Shortcut ──────────────────────────────────────────────────────────

class _WalletShortcutTab extends StatelessWidget {
  const _WalletShortcutTab();

  @override
  Widget build(BuildContext context) {
    // Full wallet screen is at AppRoutes.wallet; redirect on tab tap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.push(AppRoutes.wallet);
    });
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

// ─── Driver Profile ───────────────────────────────────────────────────────────

class _DriverProfileTab extends StatelessWidget {
  const _DriverProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driver = auth.driver;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      child: const Icon(Icons.local_shipping_rounded,
                          color: AppColors.primary, size: 40),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(driver?.name ?? '', style: AppTextStyles.h2),
                Text(driver?.phone ?? '',
                    style: AppTextStyles.bodySecondary),
                const SizedBox(height: 4),
                if (driver != null)
                  Text('⭐ ${driver.rating.toStringAsFixed(1)} · ${driver.totalJobs} missions',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (driver != null) ...[
            _InfoTile(label: 'Type de camion', value: driver.truckType),
            _InfoTile(label: 'Ville', value: driver.city),
            _InfoTile(
                label: 'Prix/km',
                value: '${driver.pricePerKm.toStringAsFixed(0)} MAD'),
          ],
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: const Text('Paramètres'),
            onTap: () => context.push(AppRoutes.settings),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: const Text('Aide & Support'),
            onTap: () => context.push(AppRoutes.support),
          ),
          ListTile(
            leading:
                const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text('Déconnexion',
                style:
                    AppTextStyles.bodyLarge.copyWith(color: AppColors.error)),
            onTap: () async {
              await auth.signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySecondary),
          Text(value, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}

class S {
  static const String lowBalanceTitle = 'Solde insuffisant';
  static const String lowBalanceMsg =
      'Votre solde est en dessous de 50 MAD. Rechargez pour continuer à accepter des missions.';
}
