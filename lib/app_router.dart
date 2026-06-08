import 'package:go_router/go_router.dart';
import 'core/constants/app_routes.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/otp_screen.dart';
import 'presentation/screens/auth/user_type_screen.dart';
// Client
import 'presentation/screens/client/client_home_screen.dart';
import 'presentation/screens/client/post_job_screen.dart';
import 'presentation/screens/client/job_posted_screen.dart';
import 'presentation/screens/client/driver_offers_screen.dart';
import 'presentation/screens/client/job_tracking_screen.dart';
import 'presentation/screens/client/job_complete_screen.dart';
// Driver
import 'presentation/screens/driver/driver_registration_screen.dart';
import 'presentation/screens/driver/driver_home_screen.dart';
import 'presentation/screens/driver/job_detail_screen.dart';
import 'presentation/screens/driver/wallet_screen.dart';
import 'presentation/screens/driver/topup_screen.dart';
// Shared
import 'presentation/screens/shared/support_screen.dart';
import 'presentation/screens/shared/settings_screen.dart';

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: AppRoutes.splash,
    routes: [
      // ── Auth & Onboarding ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.userTypeSelect,
        builder: (_, _) => const UserTypeScreen(),
      ),

      // ── Client ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.clientHome,
        builder: (_, _) => const ClientHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.postJob,
        builder: (_, _) => const PostJobScreen(),
      ),
      GoRoute(
        path: AppRoutes.jobPosted,
        builder: (_, state) {
          final jobId = state.extra as String;
          return JobPostedScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: AppRoutes.driverOffers,
        builder: (_, state) {
          final jobId = state.extra as String;
          return DriverOffersScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: AppRoutes.jobConfirmed,
        builder: (_, state) {
          final jobId = state.extra as String;
          return JobConfirmedScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: AppRoutes.jobComplete,
        builder: (_, state) {
          final jobId = state.extra as String;
          return JobCompleteScreen(jobId: jobId);
        },
      ),

      // ── Driver ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.driverRegistration,
        builder: (_, _) => const DriverRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverHome,
        builder: (_, _) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.jobDetail,
        builder: (_, state) {
          final jobId = state.extra as String;
          return JobDetailScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (_, _) => const WalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.topUp,
        builder: (_, _) => const TopUpScreen(),
      ),

      // ── Shared ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.support,
        builder: (_, _) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
  );
}
