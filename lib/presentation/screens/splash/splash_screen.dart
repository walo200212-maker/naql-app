import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../splash/wasl_app_splash_screen.dart';

/// Waits for both the splash animation to finish AND Firebase Auth to
/// restore any persisted session before deciding where to navigate.
/// On cold start, `AuthProvider.status` can still be `unknown` when the
/// (short) splash animation ends — navigating immediately in that case
/// would send a logged-in user to onboarding. A timeout guards against
/// the rare case where auth state never resolves (e.g. fully offline).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _animationDone = false;
  bool _navigated = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(seconds: 5), () => _tryNavigate(force: true));
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _tryNavigate({bool force = false}) {
    if (_navigated || !mounted) return;
    final auth = context.read<AuthProvider>();
    if (!force && (!_animationDone || auth.status == AuthStatus.unknown)) {
      return;
    }
    _navigated = true;
    _timeoutTimer?.cancel();
    if (auth.status == AuthStatus.authenticated) {
      context.go(
          auth.isDriver ? AppRoutes.driverHome : AppRoutes.clientHome);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when auth status resolves so we can re-check navigation.
    context.watch<AuthProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryNavigate());

    return WaslAppSplashScreen(
      onAnimationComplete: () {
        _animationDone = true;
        _tryNavigate();
      },
    );
  }
}
