import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../widgets/common/wasl_button.dart';

class _OBData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;

  const _OBData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}

const _pages = [
  _OBData(
    icon: Icons.inventory_2_rounded,
    iconBg: Color(0xFF162616),
    iconColor: AppColors.success,
    title: 'انقل عفشك بسهولة',
    subtitle: 'ابحث عن سائق موثوق في مدينتك\nفي أقل من دقيقة واحدة.',
    badge: '🏠',
  ),
  _OBData(
    icon: Icons.compare_arrows_rounded,
    iconBg: Color(0xFF0A1A2E),
    iconColor: AppColors.info,
    title: 'قارن الأسعار',
    subtitle: 'احصل على عروض متعددة من سائقين\nواختر الأفضل لك.',
    badge: '💰',
  ),
  _OBData(
    icon: Icons.verified_rounded,
    iconBg: Color(0xFF2E1A0A),
    iconColor: AppColors.primary,
    title: 'سائقون موثوقون 100%',
    subtitle: 'كل سائق تم التحقق منه يدوياً.\nأمانك وراحتك أولويتنا.',
    badge: '✅',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go(AppRoutes.clientHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.go(AppRoutes.clientHome),
                    child: Text(
                      'تخطي',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
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
                dotColor: AppColors.surfaceBorder,
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3,
                spacing: 6,
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: WaslButton(
                label: _current < _pages.length - 1 ? 'التالي' : 'ابدأ دابا',
                onPressed: _next,
                icon: _current < _pages.length - 1
                    ? Icons.arrow_forward_rounded
                    : Icons.rocket_launch_rounded,
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
  final _OBData page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: page.iconBg,
                  borderRadius: BorderRadius.circular(48),
                  border: Border.all(
                    color: page.iconColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(page.icon, size: 96, color: page.iconColor),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.75, 0.75),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms),

              // Badge emoji
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Center(
                  child: Text(page.badge, style: const TextStyle(fontSize: 22)),
                ),
              )
                  .animate(delay: 300.ms)
                  .scale(
                    begin: const Offset(0, 0),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),
            ],
          ),

          const SizedBox(height: 48),

          Text(
            page.title,
            style: GoogleFonts.cairo(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 100.ms)
              .slideY(begin: 0.2, end: 0, duration: 450.ms, curve: Curves.easeOutCubic)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          Text(
            page.subtitle,
            style: AppTextStyles.bodySecondary.copyWith(height: 1.8),
            textAlign: TextAlign.center,
          )
              .animate(delay: 200.ms)
              .slideY(begin: 0.2, end: 0, duration: 450.ms, curve: Curves.easeOutCubic)
              .fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}
