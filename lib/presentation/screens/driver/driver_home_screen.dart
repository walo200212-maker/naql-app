import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/wasl_shimmer.dart';
import '../../widgets/common/wasl_button.dart';

// Arabic truck type labels
const _truckLabels = {
  'Petit camion': '🚐 شاحنة صغيرة',
  'Camion moyen': '🚚 شاحنة متوسطة',
  'Grand camion': '🚛 شاحنة كبيرة',
};

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
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _tab,
            children: const [
              _JobFeedTab(),
              _WalletShortcutTab(),
              _DriverProfileTab(),
            ],
          ),

          // Floating bottom nav
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _FloatingBottomNav(
              current: _tab,
              onTap: (i) => setState(() => _tab = i),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Job Feed Tab ─────────────────────────────────────────────────────────────

class _JobFeedTab extends StatelessWidget {
  const _JobFeedTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<JobProvider>();
    final driver = auth.driver;

    // Pending approval
    if (driver != null && !driver.isApproved) {
      return _PendingApprovalScreen();
    }

    // Low wallet balance block
    if (driver != null && !driver.canAcceptJobs) {
      return _BlockedScreen(
        isLowBalance: driver.walletBalance < AppConstants.minWalletBalance,
        balance: driver.walletBalance,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // App bar area
          _DriverTopBar(driver: driver),

          // Online toggle
          _OnlineToggle(
            isOnline: driver?.isOnline ?? false,
            onToggle: (val) =>
                context.read<AuthProvider>().toggleOnline(val),
          ),

          const SizedBox(height: 8),

          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('الطلبات المتاحة', style: AppTextStyles.h3),
                const SizedBox(width: 8),
                if (provider.openJobs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGlow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${provider.openJobs.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Job list
          Expanded(
            child: provider.openJobs.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    children: const [
                      WaslShimmerList(count: 3),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: provider.openJobs.length,
                    itemBuilder: (ctx, i) {
                      final job = provider.openJobs[i];
                      return _JobCard(job: job, driver: driver)
                          .animate(delay: Duration(milliseconds: i * 70))
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.07, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Driver top bar ───────────────────────────────────────────────────────────

class _DriverTopBar extends StatelessWidget {
  final dynamic driver;

  const _DriverTopBar({this.driver});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
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
              child: const Icon(Icons.local_shipping_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('مرحباً 👋',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textHint)),
                  Text(
                    driver?.name ?? 'سائق',
                    style: AppTextStyles.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Wallet balance chip
            if (driver != null)
              GestureDetector(
                onTap: () => context.push(AppRoutes.wallet),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: driver.walletBalance < AppConstants.lowWalletWarning
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.primaryGlow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          driver.walletBalance < AppConstants.lowWalletWarning
                              ? AppColors.error.withValues(alpha: 0.4)
                              : AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 13,
                        color: driver.walletBalance <
                                AppConstants.lowWalletWarning
                            ? AppColors.error
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        CurrencyFormatter.formatCompact(
                            driver.walletBalance),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: driver.walletBalance <
                                  AppConstants.lowWalletWarning
                              ? AppColors.error
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push(AppRoutes.notifications),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: AppColors.textPrimary, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Online / Offline toggle ──────────────────────────────────────────────────

class _OnlineToggle extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onToggle;

  const _OnlineToggle({required this.isOnline, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOnline
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.surfaceBorder,
        ),
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.1),
                  blurRadius: 12,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.textHint,
              shape: BoxShape.circle,
              boxShadow: isOnline
                  ? [
                      BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.5),
                          blurRadius: 8)
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'متاح للعمل' : 'غير متاح',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isOnline
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isOnline
                      ? 'مرئي للعملاء • الموقع نشط'
                      : 'فعّل للحصول على الطلبات',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: isOnline,
            onChanged: onToggle,
            activeTrackColor: AppColors.success.withValues(alpha: 0.3),
            activeThumbColor: AppColors.success,
            inactiveTrackColor: AppColors.surfaceBorder,
            inactiveThumbColor: AppColors.textHint,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─── Job card ─────────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final JobModel job;
  final dynamic driver;

  const _JobCard({required this.job, this.driver});

  @override
  Widget build(BuildContext context) {
    final commission = job.distanceKm *
        (driver?.pricePerKm ?? 8.0) *
        AppConstants.commissionRate;
    final walletAfter = (driver?.walletBalance ?? 0.0) - commission;
    final isCritical = walletAfter < 0;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.jobDetail, extra: job.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGlow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    job.city,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                if (job.isIntercity) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'بين المدن',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${job.distanceKm.toStringAsFixed(1)} كم',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Route
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle,
                        color: AppColors.success, size: 10),
                    Container(
                      width: 1.5,
                      height: 20,
                      color: AppColors.surfaceBorder,
                    ),
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.primary, size: 14),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.pickupLocation.address,
                        style: AppTextStyles.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        job.dropoffLocation.address,
                        style: AppTextStyles.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(color: AppColors.surfaceBorder, height: 1),
            const SizedBox(height: 10),

            // Commission row
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 14,
                  color: isCritical ? AppColors.error : AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.caption,
                      children: [
                        const TextSpan(text: 'عمولة: '),
                        TextSpan(
                          text:
                              '${commission.toStringAsFixed(0)} درهم',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' • الرصيد بعد: '),
                        TextSpan(
                          text:
                              '${walletAfter.toStringAsFixed(0)} درهم',
                          style: AppTextStyles.caption.copyWith(
                            color: isCritical
                                ? AppColors.error
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGlow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'تقديم عرض',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pending approval screen ──────────────────────────────────────────────────

class _PendingApprovalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_empty_rounded,
                      color: AppColors.warning, size: 48),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 28),
                Text(
                  'حسابك قيد المراجعة ⏳',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'يتم مراجعة ملفك من طرف الإدارة.\nستتلقى إشعاراً خلال 24 ساعة.',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                WaslButton(
                  label: 'المساعدة والدعم',
                  variant: WaslButtonVariant.outline,
                  onPressed: () => context.push(AppRoutes.support),
                  icon: Icons.help_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Blocked (low balance) screen ─────────────────────────────────────────────

class _BlockedScreen extends StatelessWidget {
  final bool isLowBalance;
  final double balance;

  const _BlockedScreen(
      {required this.isLowBalance, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_rounded,
                      color: AppColors.error, size: 48),
                )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 28),
                Text(
                  isLowBalance ? 'رصيد غير كافٍ' : 'الحساب موقوف',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  isLowBalance
                      ? 'رصيدك أقل من 50 درهم. اشحن المحفظة للاستمرار في قبول الطلبات.'
                      : 'حسابك موقوف مؤقتاً من طرف الإدارة.',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (isLowBalance)
                  WaslButton(
                    label: 'شحن المحفظة الآن',
                    onPressed: () => context.push(AppRoutes.topUp),
                    icon: Icons.add_rounded,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Wallet Shortcut Tab ──────────────────────────────────────────────────────

class _WalletShortcutTab extends StatelessWidget {
  const _WalletShortcutTab();

  @override
  Widget build(BuildContext context) {
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

// ─── Driver Profile Tab ───────────────────────────────────────────────────────

class _DriverProfileTab extends StatelessWidget {
  const _DriverProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driver = auth.driver;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'ملفي الشخصي',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Profile hero
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                Stack(
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
                      child: const Icon(Icons.local_shipping_rounded,
                          color: AppColors.primary, size: 38),
                    ),
                    if (driver?.isApproved == true)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(driver?.name ?? '', style: AppTextStyles.h2),
                Text(driver?.phone ?? '',
                    style: AppTextStyles.bodySecondary),
                if (driver != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${driver.rating.toStringAsFixed(1)} • ${driver.totalJobs} مهمة',
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, end: 0),

          const SizedBox(height: 16),

          if (driver != null) ...[
            _InfoCard(items: [
              _InfoRow(
                icon: Icons.local_shipping_rounded,
                label: 'نوع الشاحنة',
                value: _truckLabels[driver.truckType] ?? driver.truckType,
              ),
              _InfoRow(
                icon: Icons.location_city_rounded,
                label: 'المدينة',
                value: driver.city,
              ),
              _InfoRow(
                icon: Icons.speed_rounded,
                label: 'السعر/كم',
                value: '${driver.pricePerKm.toStringAsFixed(0)} درهم',
                valueColor: AppColors.primary,
              ),
            ]).animate(delay: 80.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
          ],

          _MenuCard(
            items: [
              _MenuRow(
                icon: Icons.settings_rounded,
                label: 'الإعدادات',
                onTap: () => context.push(AppRoutes.settings),
              ),
              _MenuRow(
                icon: Icons.help_outline_rounded,
                label: 'المساعدة والدعم',
                onTap: () => context.push(AppRoutes.support),
              ),
              _MenuRow(
                icon: Icons.logout_rounded,
                label: 'تسجيل الخروج',
                color: AppColors.error,
                onTap: () async {
                  await auth.signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                },
              ),
            ],
          ).animate(delay: 120.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

// ─── Profile shared widgets ───────────────────────────────────────────────────

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(item.icon,
                        size: 16, color: AppColors.textHint),
                    const SizedBox(width: 10),
                    Text(item.label,
                        style: AppTextStyles.bodySecondary),
                    const Spacer(),
                    Text(
                      item.value,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: item.valueColor ?? AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                      color: AppColors.surfaceBorder, height: 1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuRow {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuRow(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});
}

class _MenuCard extends StatelessWidget {
  final List<_MenuRow> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                title: Text(item.label,
                    style: AppTextStyles.body.copyWith(color: c)),
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
    );
  }
}

// ─── Floating bottom nav ──────────────────────────────────────────────────────

class _FloatingBottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _FloatingBottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                  color: AppColors.surfaceBorder.withValues(alpha: 0.6)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                _NavItem(
                    icon: Icons.work_outline_rounded,
                    label: 'الطلبات',
                    selected: current == 0,
                    onTap: () => onTap(0)),
                _NavItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'المحفظة',
                    selected: current == 1,
                    onTap: () => onTap(1)),
                _NavItem(
                    icon: Icons.person_rounded,
                    label: 'ملفي',
                    selected: current == 2,
                    onTap: () => onTap(2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryGlow
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.primary : AppColors.textHint,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.primary : AppColors.textHint,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
