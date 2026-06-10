import 'dart:math';
import 'package:flutter/material.dart';

class WaslShakeWidget extends StatefulWidget {
  final Widget child;
  const WaslShakeWidget({super.key, required this.child});

  @override
  State<WaslShakeWidget> createState() => WaslShakeWidgetState();
}

class WaslShakeWidgetState extends State<WaslShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void shake() => _ctrl.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(sin(_ctrl.value * pi * 5) * 7, 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}
