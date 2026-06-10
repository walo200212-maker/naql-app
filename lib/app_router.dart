import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_routes.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/otp_screen.dart';
import 'presentation/screens/auth/password_screen.dart';
import 'presentation/screens/auth/permissions_screen.dart';
import 'presentation/screens/auth/user_type_screen.dart';
import 'presentation/screens/auth/welcome_screen.dart';
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
import 'presentation/screens/shared/notifications_screen.dart';
import 'presentation/screens/shared/support_screen.dart';
import 'presentation/screens/shared/settings_screen.dart';

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // ── Auth & Onboarding ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, state) => _fadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, state) => _fadePage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.otp,
        pageBuilder: (_, state) {
          final phone = state.extra as String? ?? '';
          return _fadePage(state, OtpScreen(phoneNumber: phone));
        },
      ),
      GoRoute(
        path: AppRoutes.password,
        pageBuilder: (_, state) {
          final email = state.extra as String? ?? '';
          return _fadePage(state, PasswordScreen(email: email));
        },
      ),
      GoRoute(
        path: AppRoutes.userTypeSelect,
        pageBuilder: (_, state) =>
            _fadePage(state, const UserTypeScreen()),
      ),
      GoRoute(
        path: AppRoutes.permissions,
        pageBuilder: (_, state) {
          final role = state.extra as String? ?? 'client';
          return _fadePage(state, PermissionsScreen(role: role));
        },
      ),
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (_, state) => _fadePage(state, const WelcomeScreen()),
      ),

      // ── Client ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.clientHome,
        pageBuilder: (_, state) =>
            _fadePage(state, const ClientHomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.postJob,
        pageBuilder: (_, state) => _fadePage(state, const PostJobScreen()),
      ),
      GoRoute(
        path: AppRoutes.jobPosted,
        pageBuilder: (_, state) {
          final jobId = state.extra as String;
          return _fadePage(state, JobPostedScreen(jobId: jobId));
        },
      ),
      GoRoute(
        path: AppRoutes.driverOffers,
        pageBuilder: (_, state) {
          final jobId = state.extra as String;
          return _fadePage(state, DriverOffersScreen(jobId: jobId));
        },
      ),
      GoRoute(
        path: AppRoutes.jobConfirmed,
        pageBuilder: (_, state) {
          final jobId = state.extra as String;
          return _fadePage(state, JobConfirmedScreen(jobId: jobId));
        },
      ),
      GoRoute(
        path: AppRoutes.jobComplete,
        pageBuilder: (_, state) {
          final jobId = state.extra as String;
          return _fadePage(state, JobCompleteScreen(jobId: jobId));
        },
      ),

      // ── Driver ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.driverRegistration,
        pageBuilder: (_, state) =>
            _fadePage(state, const DriverRegistrationScreen()),
      ),
      GoRoute(
        path: AppRoutes.driverHome,
        pageBuilder: (_, state) =>
            _fadePage(state, const DriverHomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.jobDetail,
        pageBuilder: (_, state) {
          final jobId = state.extra as String;
          return _fadePage(state, JobDetailScreen(jobId: jobId));
        },
      ),
      GoRoute(
        path: AppRoutes.wallet,
        pageBuilder: (_, state) => _fadePage(state, const WalletScreen()),
      ),
      GoRoute(
        path: AppRoutes.topUp,
        pageBuilder: (_, state) => _fadePage(state, const TopUpScreen()),
      ),

      // ── Shared ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (_, state) =>
            _fadePage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.support,
        pageBuilder: (_, state) =>
            _fadePage(state, const SupportScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (_, state) =>
            _fadePage(state, const SettingsScreen()),
      ),
    ],
  );
}
