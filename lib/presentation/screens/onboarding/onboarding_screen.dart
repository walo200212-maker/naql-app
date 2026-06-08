import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import '../../widgets/common/naql_button.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBg,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.inventory_2_rounded,
    title: S.ob1Title,
    subtitle: S.ob1Subtitle,
    iconBg: Color(0xFF1A2E1A),
  ),
  _OnboardingPage(
    icon: Icons.compare_arrows_rounded,
    title: S.ob2Title,
    subtitle: S.ob2Subtitle,
    iconBg: Color(0xFF1A1A2E),
  ),
  _OnboardingPage(
    icon: Icons.account_balance_wallet_rounded,
    title: S.ob3Title,
    subtitle: S.ob3Subtitle,
    iconBg: Color(0xFF2E1A0A),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(S.skip,
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary)),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageContent(page: _pages[i]),
              ),
            ),

            // Dots
            SmoothPageIndicator(
              controller: _controller,
              count: _pages.length,
              effect: ExpandingDotsEffect(
                activeDotColor: AppColors.primary,
                dotColor: AppColors.surfaceVariant,
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3,
              ),
            ),

            const SizedBox(height: 32),

            // CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: NaqlButton(
                label: _currentPage < 2 ? S.next : S.getStarted,
                onPressed: _next,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration container
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: page.iconBg,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Icon(
              page.icon,
              size: 88,
              color: AppColors.primary,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 40),

          Text(
            page.title,
            style: AppTextStyles.h1,
            textAlign: TextAlign.center,
          )
              .animate(delay: 100.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          Text(
            page.subtitle,
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          )
              .animate(delay: 200.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms)
              .fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}
