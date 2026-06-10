import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../splash/wasl_app_splash_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WaslAppSplashScreen(
      onAnimationComplete: () {
        if (!context.mounted) return;
        final auth = context.read<AuthProvider>();
        if (auth.status == AuthStatus.authenticated) {
          context.go(
              auth.isDriver ? AppRoutes.driverHome : AppRoutes.clientHome);
        } else {
          context.go(AppRoutes.onboarding);
        }
      },
    );
  }
}
