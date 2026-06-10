import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/topup_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/common/wasl_button.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final auth = context.read<AuthProvider>();
    if (auth.uid != null) {
      context.read<WalletProvider>().watchTransactions(auth.uid!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final driver = auth.driver;
    final balance = driver?.walletBalance ?? 0;
    final isLow = balance < AppConstants.lowWalletWarning;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Wallet hero header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.walletGradientStart,
                      AppColors.walletGradientEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('محفظتي',
                            style: AppTextStyles.bodySecondary),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: balance),
                              duration: const Duration(milliseconds: 1400),
                              curve: Curves.easeOutExpo,
                              builder: (_, value, _) => Text(
                                value.toStringAsFixed(2),
                                style: AppTextStyles.wallet,
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .slideY(begin: 0.3, end: 0),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('MAD',
                                  style: AppTextStyles.h3.copyWith(
                                      color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Low balance warning
                        if (isLow)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: AppColors.error, size: 14),
                                const SizedBox(width: 6),
                                Text('رصيد منخفض — اشحن الآن!',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top-up button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: WaslButton(
                label: 'شحن المحفظة',
                onPressed: () => context.push(AppRoutes.topUp),
                icon: Icons.add_rounded,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
            ),
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'العمولات'),
                  Tab(text: 'الشحنات'),
                ],
              ),
            ),
          ),

          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TransactionList(transactions: wallet.transactions),
                _TopUpList(topUps: wallet.topUps),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;

  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_rounded,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('لا توجد معاملات', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (_, i) {
        final tx = transactions[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tx.isDebit
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tx.isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: tx.isDebit ? AppColors.error : AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.isDebit ? 'عمولة مخصومة' : 'شحن',
                      style: AppTextStyles.bodyLarge,
                    ),
                    Text(
                      timeago.format(tx.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tx.isDebit ? '-' : '+'}${tx.amount.toStringAsFixed(0)} MAD',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: tx.isDebit ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '→ ${tx.balanceAfter.toStringAsFixed(0)} MAD',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        )
            .animate(delay: (i * 40).ms)
            .fadeIn(duration: 300.ms);
      },
    );
  }
}

class _TopUpList extends StatelessWidget {
  final List<TopUpModel> topUps;

  const _TopUpList({required this.topUps});

  @override
  Widget build(BuildContext context) {
    if (topUps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('لا توجد شحنات', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topUps.length,
      itemBuilder: (_, i) {
        final tu = topUps[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شحن ${tu.amount.toStringAsFixed(0)} درهم',
                      style: AppTextStyles.bodyLarge,
                    ),
                    Text('المرجع: ${tu.reference}',
                        style: AppTextStyles.caption),
                    Text(
                      timeago.format(tu.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tu.status == 'confirmed'
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tu.status == 'confirmed' ? 'مؤكد' : 'قيد الانتظار',
                  style: AppTextStyles.caption.copyWith(
                    color: tu.status == 'confirmed'
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabDelegate oldDelegate) => false;
}
