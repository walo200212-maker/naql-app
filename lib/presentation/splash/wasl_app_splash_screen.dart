import 'package:flutter/material.dart';

class WaslAppSplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  const WaslAppSplashScreen({super.key, this.onAnimationComplete});

  @override
  State<WaslAppSplashScreen> createState() => _WaslAppSplashScreenState();
}

class _WaslAppSplashScreenState extends State<WaslAppSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Logo slides in from left + fades in
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  // Logo bounces on arrival
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 0–57%: slide + fade in
    _slide = Tween<Offset>(
      begin: const Offset(-0.6, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.57, curve: Curves.easeOutCubic),
    ));

    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
    ));

    // 50–100%: elastic bounce (scale overshoot)
    _bounce = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.50, 1.0, curve: Curves.elasticOut),
    ));

    _ctrl.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) => FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Transform.scale(
                scale: _bounce.value,
                child: child,
              ),
            ),
          ),
          child: Image.asset(
            'assets/images/waslapp_logoo.png',
            width: 220,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
